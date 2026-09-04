{ pkgs, ... }:
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  time.timeZone = "Europe/Warsaw";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "pl";

  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  security.sudo.wheelNeedsPassword = true;
  services.fstrim.enable = true;

  environment.systemPackages = with pkgs; [
    neovim git ripgrep fd curl wget htop tmux
    pciutils usbutils lsof file tmux
  ];
  environment.defaultPackages = [ ];   # drops nano, perl, strace defaults
  environment.variables.EDITOR = "nvim";

  documentation.nixos.enable = true;
}
