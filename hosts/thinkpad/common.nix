{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/boot.nix
    ../../modules/networking.nix
    ../../modules/ssh.nix
    ../../modules/users.nix
    ../../modules/docker.nix
    ../../modules/services.nix
  ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl2";

  # Never change this after install — it pins stateful-data migration behaviour,
  # not the package versions (those come from flake.lock).
  system.stateVersion = "26.05";
}
