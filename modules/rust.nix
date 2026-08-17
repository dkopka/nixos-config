# Rust toolchain — nixpkgs stable, system-wide, pinned by flake.lock.
#
# Deliberately NOT rustup: rustup downloads dynamically-linked binaries that
# need nix-ld shims to run on NixOS, and it reintroduces exactly the imperative
# "installed by hand" state DEPLOYMENT.md set out to eliminate. The trade-off
# is one toolchain version per system generation; see "Per-project toolchains"
# at the bottom for how to override that when a project demands it.
{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ##########################################################################
    # Core toolchain
    ##########################################################################
    rustc
    cargo
    clippy          # cargo clippy — also wired as rust-analyzer's check command
    rustfmt         # cargo fmt
    rust-analyzer   # LSP server; rustaceanvim finds it on PATH

    ##########################################################################
    # Build prerequisites
    ##########################################################################
    # cargo shells out to a C compiler as its LINKER — without this, even a
    # hello-world `cargo build` fails with "linker `cc` not found". This is the
    # single most common Rust-on-NixOS surprise.
    gcc
    pkg-config      # how *-sys crates locate native libraries

    # NOTE: native libraries (openssl, sqlite, ...) are deliberately NOT here.
    # Installing openssl.dev system-wide would not even work: pkg-config does
    # not search /run/current-system/sw/lib/pkgconfig, and setting a global
    # PKG_CONFIG_PATH to compensate leaks host libraries into every project
    # build — the impurity NixOS exists to prevent. Native deps belong in the
    # project's devshell; see templates/rust-devshell/flake.nix in this repo.

    ##########################################################################
    # Everyday cargo helpers
    ##########################################################################
    cargo-nextest   # faster test runner, better output: cargo nextest run
    cargo-watch     # cargo watch -x check -x test
    cargo-edit      # cargo add / rm / upgrade

    taplo           # TOML formatter + LSP, used for Cargo.toml (see neovim.nix)
  ];

  # rust-analyzer needs the standard library SOURCE to offer completion and
  # go-to-definition inside std. The nixpkgs rustc does not ship it under
  # `rustc --print sysroot`, which is where rust-analyzer looks by default, so
  # point it at the separately packaged source tree. Without this, hovering
  # anything in std silently returns nothing.
  environment.variables.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";

  ############################################################################
  # Per-project toolchains
  ############################################################################
  # This module gives the machine ONE Rust version. When a project needs a
  # different one, or extra native dependencies, that belongs in the project's
  # own flake rather than here — drop a flake.nix in the repo:
  #
  #   {
  #     inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  #     outputs = { self, nixpkgs }:
  #       let pkgs = nixpkgs.legacyPackages.x86_64-linux; in {
  #         devShells.x86_64-linux.default = pkgs.mkShell {
  #           buildInputs = with pkgs; [ rustc cargo sqlite ];  # project deps
  #           RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  #         };
  #       };
  #   }
  #
  # then `nix develop`. Add direnv + nix-direnv later if you want that shell
  # entered automatically on cd.
  #
  # If you eventually need nightly or rust-toolchain.toml pinning, the step up
  # is adding oxalica/rust-overlay as a flake input — a change to flake.nix,
  # not to this module.
}
