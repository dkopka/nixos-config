# agenix — the runtime secrets layer.
#
# WHAT LIVES WHERE
#   secrets.nix          recipient rules: which public key may decrypt what.
#                        Read by the agenix CLI only, never by this module.
#   secrets/*.age        the ciphertexts. Safe in the PUBLIC repo — age
#                        blobs readable only by the ThinkPad's SSH host key
#                        or the MacBook admin key (keys.nix).
#   /run/agenix/<name>   the plaintext at runtime: ramfs, root-owned 0400,
#                        re-created on every activation, never on disk.
#
# WHY NOT the private/ layer?
#   private/ holds BUILD-time values (LUKS UUID, hardware-configuration.nix)
#   that Nix must read while *evaluating* the config. agenix decrypts at
#   *activation*, so its secrets can only ever be referenced by path. That is
#   exactly right for credentials (password hash, Wi-Fi PSK, WireGuard key)
#   and structurally impossible for a UUID baked into the initrd.
#
# ORDERING (the reason a password hash can live here at all)
#   agenix declares `system.activationScripts.users.deps = [ "agenixInstall" ]`,
#   so secrets are decrypted BEFORE NixOS builds /etc/shadow from
#   users.users.*.hashedPasswordFile. No race, no first-boot chicken-and-egg —
#   provided the decryption identity below already exists (see BOOTSTRAP).
#
# BOOTSTRAP / RECOVERY
#   The identity is the machine's OpenSSH host key, which sshd would otherwise
#   only create when the service first starts — i.e. after the first
#   activation. INSTALL.md 7.1(b) therefore generates it in the installer,
#   before `nixos-install`. If the key is missing or the secret was encrypted
#   to a different one, activation fails on the decryption step; recover by
#   booting the previous generation (or the installer + nixos-enter), fixing
#   keys.nix and re-keying — see README "Secrets".
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.thinkpad.secrets;
in
{
  imports = [ inputs.agenix.nixosModules.default ];

  options.thinkpad.secrets.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Declare the agenix secrets this host decrypts at activation.

      Turned off by exactly one consumer: the CI/VM fixture
      (checks/fixtures/ci-overrides.nix), which has no ThinkPad host key and
      therefore cannot decrypt anything. It is a flag rather than a
      `mkForce`-d empty `age.secrets` on purpose — the module system forces a
      definition to weak head normal form *before* priorities discard it, so
      `mkForce` would not stop `config.age.secrets.user-password.path` in
      modules/users.nix from being evaluated (and throwing "attribute
      missing"). `mkIf` on this flag drops that definition unevaluated.
    '';
  };

  config = lib.mkMerge [
    {
      # Identities the machine decrypts WITH. Only the ed25519 host key: the
      # RSA one would work too, but pinning a single key keeps re-keying
      # unambiguous. Harmless when no secret is declared.
      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      # The CLI, on the machine itself: `agenix -e secrets/user-password.age`,
      # `agenix --rekey`. Built from the pinned nixpkgs (flake.nix: inputs
      # follow). Unconditional, so the VM boot test can assert the wiring
      # even where decryption is out of scope.
      environment.systemPackages = [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    }

    (lib.mkIf cfg.enable {
      age.secrets.user-password = {
        file = ../secrets/user-password.age;

        # Consumed by the `users` activation script (modules/users.nix),
        # which runs as root before the account exists — so root:root 0400 is
        # both sufficient and the tightest mode available. Anything looser
        # would expose the hash to offline cracking by any local process.
        mode = "0400";
        owner = "root";
        group = "root";
        # .path stays at its default, /run/agenix/user-password, and that is
        # what users.nix reads — never hard-code the string, so the two
        # cannot drift.
      };
    })
  ];
}
