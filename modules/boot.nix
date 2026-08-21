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
  # is systemd-networkd, not the legacy ip= kernel parameter.
  #
  # ClientIdentifier=mac is essential: networkd's default is a DUID derived
  # from /etc/machine-id, but the real machine-id sits on the still-locked
  # LUKS root, so stage 1 gets a RANDOM transient one every boot -> new DUID
  # -> the DHCP server hands out a different IP on every reboot. Keying the
  # lease to the MAC makes it stable and lets a router-side DHCP reservation
  # apply to both stage 1 and the booted system (NetworkManager also keys by
  # MAC — see modules/networking.nix).
  boot.initrd.systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "ipv4";
      dhcpV4Config = {
        ClientIdentifier = "mac";
        # DHCP option 12. Routers that register leases in local DNS
        # (dnsmasq-based: OpenWrt, Pi-hole, many ISP boxes) will resolve
        # thinkpad-initrd.lan -> unlock prompt, distinct from "thinkpad"
        # which stage 2 registers.
        Hostname = "thinkpad-initrd";
      };
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
