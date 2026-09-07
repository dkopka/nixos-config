{ pkgs, inputs, ... }:
{
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # Daily-driver CLI tools that aren't already in modules/core.nix's
  # environment.systemPackages. Add to this list as you find gaps.
  home.packages = with pkgs; [
    fzf
    bat
    gitmux  # tmux status-right (home/tmux.conf) shells out to this
  ];

# Vendored as-is from ~/.tmux.conf. The tmux-resurrect plugin still needs
  # TPM installed manually the first time:
  #   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  #   (inside tmux) prefix + I
  home.file.".tmux.conf".source = ./tmux.conf;
}
