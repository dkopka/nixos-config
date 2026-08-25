# agenix RECIPIENT RULES — which public keys can decrypt which secret.
#
# Read by the `agenix` CLI only (`agenix -e ...`, `agenix --rekey`), never by
# the NixOS module system: nothing here ends up in the system closure. The
# module side lives in modules/secrets.nix.
#
# Both recipients are needed for every secret:
#   thinkpadHost — the machine decrypts at activation with its SSH host key
#   macbook      — the admin edits/re-keys without touching the ThinkPad
# Drop the host key and the machine can't read its own secrets; drop the
# admin key and a wiped ThinkPad locks you out of your own ciphertext.
#
# Adding a recipient (new machine, new admin key) is a two-step act:
# add it to keys.nix, list it here, then `agenix --rekey` — existing .age
# files are NOT retroactively readable by a key added after they were written.
let
  keys = import ./keys.nix;

  # Everything the ThinkPad needs at runtime.
  thinkpad = [ keys.thinkpadHost keys.macbook ];
in
{
  # dkopka's login password, yescrypt hash as produced by `mkpasswd`.
  # Consumed via users.users.dkopka.hashedPasswordFile (modules/users.nix).
  "secrets/user-password.age".publicKeys = thinkpad;
}
