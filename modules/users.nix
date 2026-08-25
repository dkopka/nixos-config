# User account. All user-facing packages declared here — nothing installed by hand.
{ config, lib, pkgs, ... }:

let
  keys = import ../keys.nix;
in
{
  # Fully declarative user database: users not declared here are REMOVED on
  # rebuild, and imperative `passwd` changes are reverted at activation.
  users.mutableUsers = false;

  # root: locked. No password ("!" never matches), no SSH (ssh.nix),
  # all administration via sudo from wheel.
  users.users.root.hashedPassword = "!";

  users.users.dkopka = {
    isNormalUser = true;
    description = "Dariusz Kopka";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keys = [ keys.macbook ];

    # Password hash comes from agenix (modules/secrets.nix): the yescrypt
    # hash is committed to the public repo as secrets/user-password.age and
    # decrypted to a ramfs path at activation, before this account is built.
    # Rotating it is a normal commit — `agenix -e secrets/user-password.age`
    # then rebuild — no machine-local file to remember, nothing to re-create
    # after a reinstall.
    #
    # mkIf, not a bare reference: where the secret is not declared (the CI/VM
    # fixture, which has no key to decrypt with) this definition must vanish
    # UNEVALUATED, because config.age.secrets.user-password would not exist.
    # See the option's description in modules/secrets.nix.
    hashedPasswordFile =
      lib.mkIf config.thinkpad.secrets.enable
        config.age.secrets.user-password.path;

    packages = with pkgs; [
      git
      htop
      ripgrep
      fd
      jq
      tree
      # toolchain grows here, declaratively
    ];
  };

  # Sudo for wheel; require password (flip to true only if you accept the risk)
  security.sudo.wheelNeedsPassword = true;

  environment.systemPackages = with pkgs; [
    vim   # rescue editor independent of the neovim module
    curl
    pciutils   # lspci — the tool that verified e1000e
    usbutils
  ];
}
