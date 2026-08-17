# Bootloader, initrd networking (e1000e) and remote LUKS unlock over SSH.
# The LUKS device itself (UUID) lives in private/luks.nix.
{ config, lib, pkgs, ... }:

let
  keys = import ../keys.nix;
in
{
  ############################
  # Bootloader — systemd-boot on the unencrypted ESP
  ############################
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;  # keep the 1 GB ESP tidy
  boot.loader.efi.canTouchEfiVariables = true;

  # Hibernation to the encrypted swap LV (safe: swap sits inside the LUKS container)
  boot.resumeDevice = "/dev/nixos/swap";

  ############################
  # Early-boot networking — the e1000e requirement
  ############################
  # nixos-generate-config seeds storage modules (nvme, xhci_pci, ...) in
  # private/hardware-configuration.nix; e1000e is OUR addition so the NIC
  # exists before the disk is unlocked. Verified via `lspci -k` (Phase 6).
  boot.initrd.availableKernelModules = [ "e1000e" ];

  # NixOS 26.05 boots stage 1 with systemd by default, so early networking
  # is systemd-networkd, not the legacy ip= kernel parameter. DHCP on any
  # wired interface; pin a lease to the MAC on the router for a stable
  # address at the passphrase prompt.
  boot.initrd.systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "ipv4";
      linkConfig.RequiredForOnline = "routable";
    };
  };

  ############################
  # Remote LUKS unlock over SSH (systemd stage 1 flavour)
  ############################
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      # Non-standard port so known_hosts never confuses the initrd host key
      # with the real system's host key on port 22.
      port = 2222;
      # Machine-local key, generated in INSTALL.md 7.1 — NOT in this repo.
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      # command="systemctl default" replaces the pre-26.05 postCommands/
      # cryptsetup-askpass hook: logging in over SSH immediately surfaces
      # the LUKS passphrase prompt; boot continues once entered.
      authorizedKeys = [ ''command="systemctl default" ${keys.macbook}'' ];
    };
  };

  # Optional stage-1 debugging: add "rd.systemd.debug_shell=1" to
  # boot.kernelParams, then Ctrl+Alt+F9 at the prompt for a root shell
  # (networkctl status / journalctl -u sshd from there).
}
