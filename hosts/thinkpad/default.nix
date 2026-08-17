# Host assembly for the ThinkPad — imports every module plus the private layer.
{ config, pkgs, ... }:

{
  imports = [
    # Private layer — machine identity, never in the public repo (see .gitignore)
    ../../private/hardware-configuration.nix
    ../../private/luks.nix

    # Public modules
    ../../modules/boot.nix
    ../../modules/networking.nix
    ../../modules/ssh.nix
    ../../modules/users.nix
    ../../modules/docker.nix
    ../../modules/services.nix
    ../../modules/neovim.nix
  ];

  # Nix store hygiene — per DEPLOYMENT.md "Ongoing Nix Store Hygiene"
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;   # hardlink identical store paths
      max-jobs = "auto";
      cores = 0;                    # all cores for builds
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
