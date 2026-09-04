{ config, pkgs, ... }:

let
  keys = import ../keys.nix;
in
{
  # Fully declarative user database: users not declared here are REMOVED on
  # rebuild, and imperative `passwd` changes are reverted at activation.
  users.mutableUsers = false;

  # root: locked. No password ("!" never matches), no SSH (modules/ssh.nix),
  # all administration via sudo from wheel.
  users.users.root.hashedPassword = "!";

  users.users.dkopka = {
    isNormalUser = true;
    description = "Dariusz Kopka";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keys = [ keys.macbook ];

    # Password hash lives OUTSIDE the repo, machine-local like the initrd
    # host key. Create it BEFORE the first rebuild with this config:
    #   sudo mkdir -p /etc/secrets
    #   nix shell nixpkgs#mkpasswd -c sh -c \
    #     'mkpasswd -m yescrypt | sudo tee /etc/secrets/dkopka-password >/dev/null'
    #   sudo chmod 600 /etc/secrets/dkopka-password
    # (TODO: replace with an agenix secret's .path)
    hashedPasswordFile = "/etc/secrets/dkopka-password";
  };

  # Sudo for wheel; require password
  security.sudo.wheelNeedsPassword = true;
}
