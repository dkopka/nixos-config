# Tier 4 — VM boot test (pkgs.testers.runNixOSTest, wired in flake.nix).
# Boots the configuration in QEMU on x86_64-linux and asserts the declared
# services actually come up. Run natively in CI (GitHub Actions has KVM);
# possible but slow from the MacBook (TCG emulation). See TESTING.md.
#
# The node imports hosts/thinkpad/common.nix — the SAME modules the real
# machine runs — plus overrides for what cannot exist in a VM:
#   * filesystems/bootloader: the test framework supplies its own virtual
#     disk, so the hardware fixture is NOT imported here
#   * LUKS, resume device, initrd networking: bound to real disk/NIC identity;
#     with a dummy LUKS UUID the initrd would wait forever for a device that
#     never appears, so these are forced off for the VM only
{ lib, ... }:

{
  name = "thinkpad-boot";

  # The test framework normally shares ONE read-only nixpkgs across nodes,
  # which forbids nodes from defining nixpkgs.config — but common.nix sets
  # allowUnfreePredicate (license-less vim plugins). Let the node instantiate
  # its own nixpkgs instead of forking common.nix for the VM.
  node.pkgsReadOnly = false;

  nodes.machine = {
    imports = [
      ../hosts/thinkpad/common.nix
      ./fixtures/ci-overrides.nix
    ];

    # VM-only hardware adaptations (see header comment)
    boot.initrd.luks.devices = lib.mkForce { };
    boot.resumeDevice = lib.mkForce "";
    boot.initrd.systemd.network.enable = lib.mkForce false;
    boot.initrd.network.enable = lib.mkForce false;
    boot.loader.systemd-boot.enable = lib.mkForce false;   # test VM boots kernel directly
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

    # The test driver drives the VM through a backdoor console, not the
    # network, so NetworkManager managing the virtual NIC is harmless.

    # Cede root to the harness. The framework injects its own
    # hashedPasswordFile for root (its driver credential), which under
    # mutableUsers=false outranks and overrides users.nix's
    # hashedPassword="!" anyway — nulling ours acknowledges that instead
    # of emitting a multiple-password-options eval warning on every run.
    users.users.root.hashedPassword = lib.mkForce null;
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    with subtest("sshd is up, key-only, no root"):
        machine.wait_for_unit("sshd.service")
        machine.succeed("grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config")
        machine.succeed("grep -q 'PermitRootLogin no' /etc/ssh/sshd_config")

    with subtest("docker daemon runs with the declared data-root"):
        machine.wait_for_unit("docker.service")
        machine.succeed("docker info --format '{{.DockerRootDir}}' | grep -qx /var/docker")

    with subtest("time sync + firewall + fstrim timer"):
        machine.wait_for_unit("chronyd.service")
        machine.wait_for_unit("firewall.service")
        machine.succeed("systemctl is-enabled fstrim.timer")

    with subtest("declarative user with SSH key"):
        machine.succeed("id dkopka")
        machine.succeed("grep -q ssh-ed25519 /etc/ssh/authorized_keys.d/dkopka")
        # NO root-lock assertion here, deliberately: the test framework's
        # instrumentation layer overrides root's password so its driver can
        # control the VM — root's shadow entry in a test VM reflects the
        # harness, not our config. The property we own IS covered:
        #   * eval tier guarantees users.nix sets root.hashedPassword = "!"
        #   * the sshd subtest asserts PermitRootLogin no + no password auth
        # Translating hashedPassword into /etc/shadow is nixpkgs's contract,
        # verified by nixpkgs's own test suite — not something to re-test here.

    with subtest("graphical stack: greetd greeter + Hyprland UWSM session"):
        # greetd owns tty1 (the test driver talks over the backdoor console,
        # so the greeter running there is invisible to and safe for the test)
        machine.wait_for_unit("greetd.service")
        # the UWSM session entry greetd offers is the one we expect users to pick
        machine.succeed("ls /run/current-system/sw/share/wayland-sessions | grep -q hyprland-uwsm")
        # compositor + session manager binaries resolve
        machine.succeed("Hyprland --version")
        machine.succeed("command -v uwsm")
        # declarative dotfiles are in place: /etc copies + the home symlink
        machine.succeed("test -f /etc/hypr/hypridle.conf")
        machine.succeed("readlink /home/dkopka/.config/hypr/hyprland.conf | grep -qx /etc/hypr/hyprland.conf")
        # fontconfig resolves the declared mono font
        machine.succeed("fc-list | grep -qi jetbrains")
        # pipewire is socket/user-session activated — its presence in the
        # closure is asserted here; runtime behaviour needs a logged-in seat
        machine.succeed("command -v wpctl")

    with subtest("toolchain on PATH"):
        machine.succeed("rustc --version")
        machine.succeed("cargo --version")
        machine.succeed("nvim --version")

    with subtest("identity"):
        machine.succeed("hostname | grep -qx thinkpad")
  '';
}
