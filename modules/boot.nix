{ config, lib, pkgs, ... }:

let
  keys = import ../keys.nix;
in
{
  ########################################################
  # Bootloader — systemd-boot on the unencrypted ESP
  ########################################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hibernation to the encrypted swap LV (safe: swap sits inside the LUKS container)
  boot.resumeDevice = "/dev/nixos/swap";

  # Load NIC' driver so that networkd can operate. This is a critical step.
  # For any other machine, check if 'e1000e' is the correct kernel module
  # for your hardware with `lspci -k`.
  boot.initrd.availableKernelModules = [ "e1000e" ];

  boot.initrd.systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "ipv4";
      dhcpV4Config = {
        # By default networkd sends a DUID derived from /etc/machine-id as
        # a DHCP client identifier. This file, however, is still on an
        # encrypted partition, so networkd gives out a random value.
        # Force MAC address as client identifier to keep IP leases stable
        # between initrd and system. Same change applies to the system side
        # (see modules/networking.nix).
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
  # Remote LUKS unlock over SSH
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
