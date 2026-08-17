{
  description = "Declarative NixOS for the ThinkPad (see DEPLOYMENT.md / INSTALL.md)";

  inputs = {
    # NixOS 26.05 "Yarara" — current stable as of Aug 2026
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Iteration 2 (post first boot): secrets layer per DEPLOYMENT.md
    # agenix.url = "github:ryantm/agenix";
    # agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.thinkpad = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/thinkpad ];
    };
  };
}
