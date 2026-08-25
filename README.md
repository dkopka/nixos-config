# nixos-config — ThinkPad

Declarative NixOS for the ThinkPad. Design rationale lives in [`../DEPLOYMENT.md`](../DEPLOYMENT.md); the install procedure in [`../INSTALL.md`](../INSTALL.md); how to verify changes before deploying in [`TESTING.md`](TESTING.md). This README covers only what you do **with this repo**.

Before every commit: `./check.sh` (syntax + full evaluation, runs on the MacBook). CI builds and boot-tests the x86_64 system on every push.

## Layout

```
flake.nix                   entry point → nixosConfigurations.thinkpad (nixos-26.05)
                            + thinkpad-ci (test variant) + checks (VM boot test)
                            inputs: nixpkgs, agenix
check.sh                    local verification — run before every commit (TESTING.md)
keys.nix                    public SSH keys (not secrets) — EDIT BEFORE INSTALL
                            admin (MacBook) + ThinkPad host key = agenix recipients
secrets.nix                 agenix recipient rules — CLI only, not in the closure
secrets/*.age               encrypted secrets, safe to commit (see "Secrets")
hosts/thinkpad/
  default.nix               real machine = common.nix + private/
  common.nix                host assembly, nix GC/hygiene, stateVersion (shared with CI)
checks/                     test framework: fixtures (stub private layer), VM boot test
.github/workflows/check.yml CI: lint, eval, x86_64 build, QEMU boot test
modules/
  boot.nix                  systemd-boot, e1000e in initrd, SSH remote unlock :2222
  networking.nix            hostname, NetworkManager, firewall
  ssh.nix                   sshd — key-only, no root
  secrets.nix               agenix: identity, secret declarations, CLI
  users.nix                 dkopka, groups, declared packages
                            (password hash comes from agenix, not a local file)
  docker.nix                docker with data-root=/var/docker + weekly prune
  services.nix              chrony, lid behaviour, fstrim
  hyprland.nix              desktop: greetd/tuigreet login, Hyprland (UWSM session),
                            pipewire, bluetooth, waybar/mako/fuzzel, hyprlock/hypridle —
                            all dotfiles declarative in /etc (pick "Hyprland (UWSM)"
                            in the greeter; config changes need `hyprctl reload`)
  neovim.nix                declarative neovim scaffold
private/                    ← gitignored, machine identity
  luks.nix                  LUKS UUID (08de1afa-…) — real value, already filled in
  hardware-configuration.nix  PLACEHOLDER — replace on install day (build fails until you do)
```

## Install day (you are at INSTALL.md Phase 7)

**1. Edit `keys.nix`** — paste your MacBook's `~/.ssh/id_ed25519.pub`. It feeds both the initrd unlock and normal SSH login.

**2. Get this folder onto the ThinkPad.** Easiest from the MacBook over the LAN — the live installer already runs sshd, it just needs a root password:

```bash
# on the ThinkPad (live installer):
passwd            # set a throwaway root password for the transfer
ip a              # note the LAN address

# on the MacBook:
scp -r "$HOME/Documents/Claude/Projects/NixOS System Config/nixos-config" root@<installer-ip>:/root/

# back on the ThinkPad:
mv /mnt/etc/nixos /mnt/etc/nixos-generated     # keep Phase 6 output aside
mv /root/nixos-config /mnt/etc/nixos
cp /mnt/etc/nixos-generated/hardware-configuration.nix /mnt/etc/nixos/private/
```

**3. Sanity-check the private layer.**

```bash
grep uuid /mnt/etc/nixos/private/luks.nix
blkid -s UUID -o value /dev/nvme0n1p2          # must match
grep e1000e /mnt/etc/nixos/private/hardware-configuration.nix || true
# hardware config may or may not list it; modules/boot.nix adds it regardless
```

**4. The two host keys** (INSTALL.md 7.1, if not done yet). Both are generated
*in the installer*, before `nixos-install`, and both stay machine-local:

```bash
# initrd key — unlocks LUKS over SSH on port 2222, before the disk exists
mkdir -p /mnt/etc/secrets/initrd
ssh-keygen -t ed25519 -N "" -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key

# system key — the identity agenix decrypts with. sshd would create this
# itself, but only when the service first starts, which is AFTER the first
# activation — too late for a password hash the activation needs.
mkdir -p /mnt/etc/ssh
ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
cat /mnt/etc/ssh/ssh_host_ed25519_key.pub     # → keys.nix thinkpadHost
```

Paste that public key into `keys.nix` as `thinkpadHost`, then (on the MacBook,
which holds the admin key) `agenix --rekey` and commit — otherwise the machine
cannot read its own secrets and dkopka's account boots locked.

**5. Install:**

```bash
nixos-install --flake /mnt/etc/nixos#thinkpad
```

> Do **not** `git init` in /mnt/etc/nixos before installing. A plain directory is a valid "path flake" and every file is visible. The moment `.git` exists, flakes see only *tracked* files — and `private/` is gitignored, so evaluation would fail with "path does not exist".

## After first boot: the public/private split

The flake gotcha above is why the split happens post-install, deliberately:

1. `git init`, commit everything **except** `private/` (the .gitignore handles it), push to the public GitHub repo.
2. Put `private/` in its own **private** repo (`nixos-secrets` per DEPLOYMENT.md) and keep a working copy at `/etc/nixos/private/`.
3. For day-to-day rebuilds nothing changes: `sudo nixos-rebuild switch --flake /etc/nixos#thinkpad` — as long as the working tree contains `private/`, add it with `git add -f private/` in a **local-only** commit you never push, or rebuild with `--override-input`/path flake. Pick one and stay consistent; the local-only `git add -f` is the simplest.
4. Runtime secrets (login password hash, later the Wi-Fi PSK and WireGuard keys) do **not** go in the private repo — they are agenix ciphertexts committed to the *public* one. See "Secrets" below. The LUKS UUID and hardware config stay private-layer: they are **build-time** values and can never be agenix secrets — see the comment in `private/luks.nix`.

## Secrets

Two layers, split by *when* the value is needed:

| | `private/` | `secrets/*.age` (agenix) |
|---|---|---|
| Contains | LUKS UUID, hardware config | password hash, PSKs, private keys |
| Needed at | Nix **evaluation** (build) | system **activation** (runtime) |
| Repo | private / local only | public — it's ciphertext |
| Reference style | value inlined in a module | path: `config.age.secrets.<name>.path` |

Recipients are declared in `secrets.nix` (rules for the CLI) and defined in
`keys.nix`: the ThinkPad's SSH **host** key so the machine can decrypt its own
secrets at activation, and the MacBook admin key so you can edit and re-key
them without the ThinkPad. Plaintext only ever exists in `$EDITOR` on tmpfs and
at `/run/agenix/<name>` (ramfs, root-only, 0400).

```bash
# create or rotate the login password hash (from the repo root, either machine)
nix run github:ryantm/agenix -- -e secrets/user-password.age
#   paste ONE line: the output of `mkpasswd -m yescrypt`, nothing else
git commit -am "secrets: rotate login password" && sudo nixos-rebuild switch --flake /etc/nixos#thinkpad

# after changing the recipient list in keys.nix/secrets.nix (new machine, new admin key)
nix run github:ryantm/agenix -- --rekey     # needs a key that can already decrypt

# on the ThinkPad the CLI is installed, so it's just: agenix -e secrets/user-password.age
```

**Ordering guarantee.** agenix sets `activationScripts.users.deps = [ "agenixInstall" ]`, so `/run/agenix/user-password` exists before NixOS writes `/etc/shadow` from `hashedPasswordFile`. No first-boot race — as long as the host key in `keys.nix` is the one actually on the machine.

**If decryption fails** (host key regenerated, secret never re-keyed): the hash file is absent, `mutableUsers = false` leaves dkopka locked, and `sudo` needs that password. SSH-key login still works, so you are not locked out of the box — but recover deliberately: boot the previous generation from systemd-boot (or the installer + `nixos-enter`), fix `keys.nix`, `agenix --rekey`, rebuild.

**Never** an agenix secret: the initrd SSH host key. agenix decrypts after the disk is unlocked, and the initrd needs that key before it — it stays a machine-local file under `/etc/secrets/initrd/`.

## Rebuild cheat-sheet

```bash
sudo nixos-rebuild switch --flake /etc/nixos#thinkpad   # apply
sudo nixos-rebuild boot   --flake /etc/nixos#thinkpad   # apply on next boot
sudo nixos-rebuild test   --flake /etc/nixos#thinkpad   # apply, not persisted
nix flake update /etc/nixos                             # bump nixpkgs, then switch
```
