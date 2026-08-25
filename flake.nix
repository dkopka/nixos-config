{
  description = "Declarative NixOS for the ThinkPad";

  inputs = {
    # NixOS 26.05 "Yarara" — current stable as of Aug 2026
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Runtime secrets layer (modules/secrets.nix). Pinned to the same nixpkgs
    # so the agenix CLI in environment.systemPackages is built from the very
    # revision flake.lock pins — no second nixpkgs in the closure.
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      # Gitignored files are INVISIBLE to a flake once .git exists, so
      # private/ is only present when the tree is consumed as `path:.`
      # (which check.sh does) or on the ThinkPad's own checkout. Guarding on
      # it keeps `nix flake check` / CI working on a git-clean clone, where
      # only thinkpad-ci exists.
      hasPrivateLayer = builtins.pathExists ./private/hardware-configuration.nix;

      # Every entry point that pulls in hosts/thinkpad/common.nix must pass
      # this: modules/secrets.nix imports the agenix NixOS module out of
      # `inputs`, so the flake's inputs have to reach the module system.
      # Three call sites: thinkpad, thinkpad-ci, and the VM test node below.
      specialArgs = { inherit inputs; };
    in
    {
      nixosConfigurations = {
        # Test/CI variant: identical public modules, stub machine identity.
        # Exists so the config can be evaluated, built, and boot-tested
        # without the private layer. NEVER deploy this to hardware.
        thinkpad-ci = lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [
            ./hosts/thinkpad/common.nix
            ./checks/fixtures/hardware-configuration.nix
            ./checks/fixtures/luks.nix
            ./checks/fixtures/ci-overrides.nix
          ];
        };
      } // lib.optionalAttrs hasPrivateLayer {
        # The real machine. Only visible when private/ is reachable — use
        # `--flake path:.#thinkpad` (not `.#thinkpad`) from a git checkout.
        thinkpad = lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [ ./hosts/thinkpad ];
        };
      };

      checks.x86_64-linux =
        let pkgs = nixpkgs.legacyPackages.x86_64-linux; in
        {
          # Tier 3 — realize every derivation of the CI variant
          system-builds = self.nixosConfigurations.thinkpad-ci.config.system.build.toplevel;

          # Tier 4 — boot it in QEMU and assert services (checks/vm-boot-test.nix)
          boot = pkgs.testers.runNixOSTest {
            imports = [ ./checks/vm-boot-test.nix ];
            node.specialArgs = specialArgs;
          };
        };
    };
}
