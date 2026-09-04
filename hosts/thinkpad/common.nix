{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/boot.nix
    ../../modules/networking.nix
    ../../modules/ssh.nix
    ../../modules/users.nix
    ../../modules/docker.nix
    ../../modules/services.nix
    ../../modules/neovim.nix
    ../../modules/rust.nix
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

  # Vim plugins whose upstream repos ship no LICENSE file. The nixpkgs plugin
  # generator can't detect an SPDX id, so it defaults meta.license = unfree —
  # this is a metadata gap, not proprietary software (fugitive is Vim-licensed,
  # nvim-tree is GPL-3). Allowlisted by exact name rather than opening up
  # allowUnfree globally.
  nixpkgs.config.allowUnfreePredicate =
    p: builtins.elem (lib.getName p) [
      "vimplugin-vim-fugitive"
      "vimplugin-nvim-tree.lua"
    ];

  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl2";

  # Never change this after install — it pins stateful-data migration behaviour,
  # not the package versions (those come from flake.lock).
  system.stateVersion = "26.05";
}
