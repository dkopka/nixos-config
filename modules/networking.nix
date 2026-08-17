# Networking — minimal for first boot; VLANs / WireGuard / dnsmasq are
# iteration 2 (they need the agenix layer for keys and Wi-Fi credentials).
{ config, pkgs, ... }:

{
  networking.hostName = "thinkpad";

  # NetworkManager for first boot: `nmtui` gets Wi-Fi up imperatively.
  # Iteration 2 replaces credentials with agenix-backed declarative config.
  networking.networkmanager.enable = true;

  networking.firewall.enable = true;
  # Nothing exposed by default; sshd adds its own port automatically.
}
