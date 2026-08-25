# FIXTURE — neutralizes the settings that reference MACHINE-LOCAL identity
# absent in tests/CI. Everything else is tested exactly as configured.
{ lib, ... }:

{
  # The initrd SSH host key lives at /etc/secrets/initrd/... on the ThinkPad
  # only (INSTALL.md 7.1). Building with a missing key path is fine for the
  # toplevel derivation, but VM tests actually assemble a bootable initrd, so
  # disable the initrd sshd here. The option VALUES in modules/boot.nix are
  # still type-checked by the eval tier against the real configuration.
  boot.initrd.network.ssh.enable = lib.mkForce false;

  # agenix: CI has no ThinkPad host key, so nothing here can decrypt
  # secrets/*.age — declaring the secret anyway would fail activation on a
  # secret this machine was never meant to read. The flag (rather than an
  # empty age.secrets) is what also drops the hashedPasswordFile definition
  # in modules/users.nix unevaluated; see the option description in
  # modules/secrets.nix for why mkForce cannot do that job.
  #
  # Still exercised in CI: the agenix module imports, evaluates, builds and
  # activates, and its CLI ships (asserted by the VM boot test). Only the
  # decryption step is out of scope — that one is verified on the machine,
  # see README "Secrets".
  thinkpad.secrets.enable = false;

  # …which leaves dkopka with no password source at all. Lock the account
  # explicitly; SSH-key login (the declared access path) remains testable.
  users.users.dkopka.hashedPassword = lib.mkForce "!";
}
