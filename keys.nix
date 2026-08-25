# Public SSH keys — NOT secrets, safe in the public repo.
# Referenced by modules/boot.nix (initrd unlock), modules/users.nix (login)
# and secrets.nix (agenix recipients — who can decrypt secrets/*.age).
{
  # Admin identity: the MacBook. Decrypts every secret so they can be edited
  # and re-keyed away from the ThinkPad.
  macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIrErh5M88xtys6qtPGUhBYVkEQafY3GehKGudJlPi/X dkopka@macbook";

  # Machine identity: the ThinkPad's OpenSSH host key (public half of
  # /etc/ssh/ssh_host_ed25519_key, generated on the box, never leaves it).
  # This is what lets the machine decrypt its own secrets at activation —
  # see modules/secrets.nix. Regenerating the host key means re-keying:
  # update this value, then `agenix --rekey`.
  thinkpadHost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzNKFhC8JriXogJEGple3Ei8egypHu6JC8ZavGOTAzD root@thinkpad";
}
