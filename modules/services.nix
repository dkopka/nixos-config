{ lib, ... }:

{
  # Time sync
  services.chrony.enable = true;

  # Lid behaviour — laptop usable as a "server" with the lid closed while
  # remote-unlocked over ethernet.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";               # on battery
    HandleLidSwitchExternalPower = "ignore";   # docked/plugged: keep running
  };

  services.fstrim.enable = true;  # weekly TRIM for the SSD (pairs with allowDiscards)
  services.tlp.enable = lib.mkForce false;
  services.thermald.enable = true;
}
