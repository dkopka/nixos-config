# Disk layout with disko

`disko.nix` in this directory is the single source of truth for the ThinkPad's
disk layout. It is used in two ways:

- **At install time** it is turned into a script that partitions, encrypts,
  creates LVM, formats, and mounts everything under `/mnt`.
- **At build time** it is a NixOS module that generates `fileSystems.*`,
  `swapDevices`, and `boot.initrd.luks.devices.*`. Nothing else in the config
  declares mounts or the LUKS device — do not add them to `hardware.nix`.

Layout: GPT → 1G ESP + LUKS (`crypted`) → LVM VG `nixos` → `swap`, `root`,
`nix`, `var`, `home` (ext4, `home` takes the remaining space).

## Wiring

- `flake.nix` has `disko` as an input with `inputs.nixpkgs.follows = "nixpkgs"`.
- `hosts/thinkpad/default.nix` imports `inputs.nixos-hardware.nixosModules.disko`
  and `./disko.nix`.
- `hardware.nix` is generated with `--no-filesystems` (see below).

## Dry run first

Always look at what disko would do before letting it touch a disk:

```sh
nix run github:nix-community/disko -- --mode disko --dry-run --flake .#thinkpad
```

Check the device path (`/dev/nvme0n1`) and the `lvcreate` sizes in the output.

## Fresh install — locally on the ThinkPad

1. Boot the NixOS installer ISO, get network, clone the repo:

   ```sh
   git clone https://github.com/dkopka/nixos-config /root/nixos-config
   cd /root/nixos-config
   ```

2. Partition, encrypt, create LVM, format, mount. **This wipes the disk.**
   disko prompts for the LUKS passphrase unless a key file is given:

   ```sh
   nix run github:nix-community/disko -- --mode disko --flake .#thinkpad
   ```

   Afterwards everything is mounted under `/mnt`, `/mnt/boot`, `/mnt/nix`, etc.

3. Regenerate `hardware.nix` **without** filesystem entries and commit it:

   ```sh
   nixos-generate-config --no-filesystems --root /mnt --show-hardware-config \
     > hosts/thinkpad/hardware.nix
   ```

4. Create the initrd SSH host key (not in git):

   ```sh
   mkdir -p /mnt/etc/secrets/initrd
   ssh-keygen -t ed25519 -N "" -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key
   ```

5. Install and reboot:

   ```sh
   nixos-install --flake .#thinkpad
   reboot
   ```

## Fresh install — remotely from another machine

Boot the target on the installer ISO, set a root password (`passwd`), note its
IP, then from the other machine:

```sh
echo -n 'passphrase' > /tmp/luks.key
nixos-anywhere --flake .#thinkpad \
  --disk-encryption-keys /tmp/luks.key /tmp/luks.key \
  root@<installer-ip>
```

This runs disko, builds the system, installs, and reboots. Do steps 3 and 4
from the local flow beforehand (the initrd host key can be copied in with
`--extra-files`). Delete `/tmp/luks.key` when done.

## Mounting an existing install from a rescue ISO

No need to remember LV names or mapper paths:

```sh
nix run github:nix-community/disko -- --mode mount --flake .#thinkpad
```

Prompts for the passphrase, then the full tree is under `/mnt`. Useful before
`nixos-enter` or `nixos-install` on a broken system.

## Modes

| `--mode` | Effect |
|----------|--------|
| `destroy` | Wipe partition table only |
| `format`  | Create partitions, LUKS, LVM, filesystems (no mount) |
| `mount`   | Mount an already-formatted layout under `/mnt` |
| `disko`   | `destroy` + `format` + `mount` — the install-day mode |

## Things to know

- disko is an **install-time** tool. Editing `disko.nix` on a running system
  changes nothing on disk; it only changes what `fileSystems` the next
  generation expects. Keep the file in sync with reality if you ever resize
  an LV by hand.
- `swap` has `resumeDevice = true`, which sets `boot.resumeDevice` so
  hibernation works (swap size equals RAM).
- `allowDiscards = true` on the LUKS layer lets `fstrim` reach the SSD.
- The LUKS UUID is generated at format time and read back by disko; it is not
  in git and does not need to be.
- To add a machine: copy `hosts/thinkpad/` to `hosts/<name>/`, adjust
  `device` and LV sizes in `disko.nix`, regenerate `hardware.nix` on the new
  box, add one line to `flake.nix`.
