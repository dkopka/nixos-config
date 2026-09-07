{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # nixos-hardware has no release branches, so an unpinned URL means
    # every `nix flake update` can silently change what a profile module enables.
    # 2026-09-02 - 44d95795ee2d475b3d687325e26dcf4ca9104557
    nixos-hardware.url = "github:NixOS/nixos-hardware/44d95795ee2d475b3d687325e26dcf4ca9104557";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    mkHost = name: system: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [ ./hosts/${name} ];
    };
  in {
    nixosConfigurations = {
      thinkpad = mkHost "thinkpad" "x86_64-linux";
    };
  };
}
