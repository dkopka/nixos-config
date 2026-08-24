# nixos-config — ThinkPad

Declarative NixOS for the ThinkPad. Design rationale lives in [`../DEPLOYMENT.md`](../DEPLOYMENT.md); the install procedure in [`../INSTALL.md`](../INSTALL.md); how to verify changes before deploying in [`TESTING.md`](TESTING.md). This README covers only what you do **with this repo**.

Before every commit: `./check.sh` (syntax + full evaluation, runs on the MacBook). CI builds and boot-tests the x86_64 system on every push.

## Layout

```
flake.nix                   entry point → nixosConfigurations.thinkpad (nixos-26.05)
                            + thinkpad-ci (test variant) + checks (VM boot test)
check.sh                    local verification — run before every commit (TESTING.md)
keys.nix                    public SSH keys (not secrets) — EDIT BEFORE INSTALL
hosts/thinkpad/
  default.nix               real machine = common.nix + private/
  common.nix                host assembly, nix GC/hygiene, stateVersion (shared with CI)
checks/                     test framework: fixtures (stub private layer), VM boot test
.github/workflows/check.yml CI: lint, eval, x86_64 build, QEMU boot test
modules/
  boot.nix                  systemd-boot, e1000e in initrd, SSH remote unlock :2222
  networking.nix            hostname, NetworkManager, firewall
  ssh.nix                   sshd — key-only, no root
  users.nix                 dkopka, groups, declared packages
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

**4. Initrd host key** (INSTALL.md 7.1, if not done yet):

```bash
mkdir -p /mnt/etc/secrets/initrd
ssh-keygen -t ed25519 -N "" -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key
```

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
4. Iteration 2 adds agenix for *runtime* secrets (Wi-Fi PSK, WireGuard keys). Note: the LUKS UUID and hardware config are **build-time** values and can never be agenix secrets — see the comment in `private/luks.nix`.

## Rebuild cheat-sheet

```bash
sudo nixos-rebuild switch --flake /etc/nixos#thinkpad   # apply
sudo nixos-rebuild boot   --flake /etc/nixos#thinkpad   # apply on next boot
sudo nixos-rebuild test   --flake /etc/nixos#thinkpad   # apply, not persisted
nix flake update /etc/nixos                             # bump nixpkgs, then switch
```
