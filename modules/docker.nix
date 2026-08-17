# Docker — data-root pinned to the dedicated /var LV so images can never
# fill the root filesystem again (the headline lesson in DEPLOYMENT.md).
{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      data-root = "/var/docker";
    };
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };
}
