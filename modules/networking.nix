{ config, pkgs, ... }:

{
  networking.hostName = "thinkpad";

  networking.networkmanager.enable = true;

  # Key DHCP leases to the MAC (client-id = MAC), matching what the initrd's
  # systemd-networkd sends (ClientIdentifier=mac in modules/boot.nix). With
  # both stages presenting the same identity, the DHCP server issues ONE
  # lease for the machine and a router-side reservation pins it for good.
  networking.networkmanager.settings = {
    connection."ipv4.dhcp-client-id" = "mac";
  };

  networking.firewall.enable = true;
}
