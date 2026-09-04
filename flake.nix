{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Pinned to an explicit rev, not a branch. nixos-hardware has no release
    # branches, so an unpinned URL means every `nix flake update` can silently
    # change what a profile module enables.
    nixos-hardware.url = "github:NixOS/nixos-hardware/44d95795ee2d475b3d687325e26dcf4ca9104557";  # 2026-09-02

    disko.url = "github:nix-community/disko/ff8702b4de27f72b4c78573dfb89ec74e36abdf1";  # 2026-06-11
    disko.inputs.nixpkgs.follows = "nixpkgs";
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
