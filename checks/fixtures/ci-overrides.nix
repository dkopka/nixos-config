# FIXTURE — neutralizes the two settings that reference MACHINE-LOCAL files
# absent in tests/CI. Everything else is tested exactly as configured.
{ lib, ... }:

{
  # The initrd SSH host key lives at /etc/secrets/initrd/... on the ThinkPad
  # only (INSTALL.md 7.1). Building with a missing key path is fine for the
  # toplevel derivation, but VM tests actually assemble a bootable initrd, so
  # disable the initrd sshd here. The option VALUES in modules/boot.nix are
  # still type-checked by the eval tier against the real configuration.
  boot.initrd.network.ssh.enable = lib.mkForce false;

  # dkopka's password hash is machine-local (/etc/secrets/dkopka-password).
  # Substitute a locked password; SSH-key login (the declared access path)
  # remains testable.
  users.users.dkopka.hashedPasswordFile = lib.mkForce null;
  users.users.dkopka.hashedPassword = lib.mkForce "!";
}
