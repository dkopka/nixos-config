# TESTING — verify the config before it touches the ThinkPad

The working machine is an aarch64 MacBook; the target is x86_64-linux. That
asymmetry shapes the whole framework: Nix **evaluation** is platform-independent,
so the entire module system — option names, types, merges, assertions — can be
verified locally in seconds. Only **building** and **booting** need x86_64, and
those run in GitHub Actions on native x86_64 runners.

## The tiers

| Tier | What | Where | Catches | Time |
|------|------|-------|---------|------|
| 1 | Parse every `.nix` file | Mac (`./check.sh`) | Syntax errors | seconds |
| 2 | Evaluate the full system derivation | Mac (`./check.sh`) | Wrong/renamed options, type errors, module conflicts, failed NixOS assertions — the large majority of real config bugs | ~1 min |
| 3 | Build the complete x86_64 closure | CI | Broken/renamed packages, unfree-license surprises, anything build-time | ~10-30 min (cached: less) |
| 4 | Boot in QEMU, assert services | CI | Runtime wiring: does sshd/docker/chrony actually start, is the user created, firewall up | ~5-10 min |

## Day-to-day workflow

```bash
./check.sh              # before every commit: tiers 1+2, both variants
./check.sh all          # + statix/deadnix lint
./check.sh eval --show-trace   # debugging an eval failure
git push                # CI runs tiers 1-4
```

**Step zero if Nix isn't installed on the Mac yet:**

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

## How the private layer is handled

`private/` (disk UUIDs, LUKS device, real hardware config) never reaches
GitHub. Tests use a parallel, committed stand-in:

```
checks/fixtures/
  hardware-configuration.nix   same shape as the real one, dummy UUIDs
  luks.nix                     dummy LUKS UUID — still exercises the initrd/cryptsetup path
  ci-overrides.nix             neutralizes what depends on MACHINE-LOCAL keys:
                               the initrd SSH host key, and agenix decryption
                               (thinkpad.secrets.enable = false — CI has no
                               host key, so dkopka's password hash cannot be
                               decrypted; the module itself is still built,
                               activated and asserted by the VM boot test)
```

`flake.nix` assembles these into **`nixosConfigurations.thinkpad-ci`** — the
same `hosts/thinkpad/common.nix` the real machine imports, different identity.
CI builds and boots `thinkpad-ci`; your Mac additionally evaluates the real
`thinkpad` (tier 2), since the private layer exists locally.

Two configs, one module set — the split lives in `hosts/thinkpad/`:

```
default.nix   real machine  = common.nix + private/
common.nix    all public modules + host settings (imported by both variants)
```

## The `path:` subtlety (important)

Once `.git` exists, flakes only see **git-tracked** files — gitignored
`private/` becomes invisible and `nix build .#thinkpad` would fail. Therefore:

- `check.sh` always references the flake as **`path:$PWD`**, which copies the
  tree unfiltered, private layer included.
- `flake.nix` guards the `thinkpad` output with `builtins.pathExists`, so a
  git-clean checkout (CI, fresh clone) cleanly exposes only `thinkpad-ci`
  instead of failing evaluation.
- Same rule applies on the ThinkPad itself:
  `nixos-rebuild switch --flake path:/etc/nixos#thinkpad`.

## What the VM boot test asserts (`checks/vm-boot-test.nix`)

Boots `common.nix` in QEMU and verifies: sshd up with key-only auth and root
login disabled; docker running with `data-root=/var/docker`; chrony, firewall,
fstrim timer active; user `dkopka` exists with the SSH key installed and root
locked; rustc/cargo/nvim on PATH; hostname correct.

VM-only overrides (in the test file, clearly marked): LUKS device, resume
device, initrd networking and bootloader are forced off — they're bound to
real disk/NIC identity a QEMU test VM doesn't have. Everything else runs the
exact modules the laptop will run.

Run tier 4 locally if you ever want to (slow — TCG emulation of x86_64 on
Apple Silicon, expect 15+ min):

```bash
nix build "path:$PWD#checks.x86_64-linux.boot" -L
```

## What still can't be tested anywhere but the machine

Real hardware identity: the actual LUKS unlock against the real UUID, the
e1000e NIC appearing in initrd, EFI variables, the machine-local secrets
(`/etc/secrets/...`). That's exactly the set INSTALL.md's phased verification
covers on install day — everything else is covered before you ever plug in.
