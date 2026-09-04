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
  # Thermals are owned by the EC via Lenovo DYTC. thermald refuses to start
  # when dytc_lapmode is present, and TLP's AC defaults drive the DYTC
  # platform_profile to "performance", pinning the fan high.
  services.tlp.enable = lib.mkForce false;
  services.thermald.enable = false;
}
