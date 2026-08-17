# Neovim — fully declared, zero post-install plugin management.
# Scaffold for first boot; expand the plugin list here, never via :PlugInstall.
{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    configure = {
      customRC = ''
        set number
        set expandtab shiftwidth=2 tabstop=2
        set ignorecase smartcase
        set clipboard=unnamedplus
      '';
      packages.myPlugins = with pkgs.vimPlugins; {
        start = [
          # Iteration 2: port the full plugin list from the old machine, e.g.:
          # telescope-nvim
          # nvim-treesitter.withAllGrammars
          # nvim-lspconfig
          # gitsigns-nvim
        ];
        opt = [ ];
      };
    };
  };

  # LSP servers / formatters the plugins call out to — also declared:
  # environment.systemPackages = with pkgs; [ nil nixpkgs-fmt lua-language-server ];
}
