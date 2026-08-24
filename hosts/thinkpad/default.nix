# Host assembly for the REAL ThinkPad: shared settings + the private layer.
# Everything public lives in common.nix so the CI/test variant (thinkpad-ci,
# see flake.nix) can reuse it with stub fixtures instead of private/.
{ ... }:

{
  imports = [
    ./common.nix

    # Private layer — machine identity, never in the public repo (see .gitignore)
    ../../private/hardware-configuration.nix
    ../../private/luks.nix
  ];
}
