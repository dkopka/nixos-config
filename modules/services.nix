# System services: time sync, lid behaviour. openvscode-server & dnsmasq are
# iteration 2 (per DEPLOYMENT.md's declaration table).
{ config, pkgs, ... }:

{
  # Time sync
  services.chrony.enable = true;

  # Lid behaviour — laptop usable as a "server" with the lid closed while
  # remote-unlocked over ethernet.
  # 26.05 renamed these into the generic logind settings passthrough:
  #   lidSwitch -> settings.Login.HandleLidSwitch
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";               # on battery
    HandleLidSwitchExternalPower = "ignore";   # docked/plugged: keep running
  };

  services.fstrim.enable = true;  # weekly TRIM for the SSD (pairs with allowDiscards)
}
