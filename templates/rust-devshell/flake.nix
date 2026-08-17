# Starter devshell for a Rust project with native dependencies.
#
#   cp -r /etc/nixos/templates/rust-devshell/flake.nix ~/src/myproject/
#   cd ~/src/myproject && nix develop
#
# Why this exists: modules/rust.nix puts one Rust toolchain on the system, but
# deliberately no native libraries — pkg-config cannot find system-wide .pc
# files, and forcing it to would leak host libs into every build. Per-project
# libraries go here instead, where they are pinned and reproducible.
{
  description = "Rust development shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        # The toolchain. Pinning it here (rather than relying on the system)
        # makes the project build identically on any machine.
        nativeBuildInputs = with pkgs; [
          rustc
          cargo
          clippy
          rustfmt
          rust-analyzer
          pkg-config
        ];

        # Native libraries this project links against — edit for your project.
        buildInputs = with pkgs; [
          openssl
          # sqlite
          # libgit2
        ];

        # std source for rust-analyzer completion (same reason as rust.nix)
        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

        shellHook = ''
          echo "rust $(rustc --version)"
        '';
      };
    };
}
