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

    with subtest("declarative user with SSH key, root locked"):
        machine.succeed("id dkopka")
        machine.succeed("grep -q ssh-ed25519 /etc/ssh/authorized_keys.d/dkopka")
        # users.nix sets root.hashedPassword = "!" (never matches) — assert
        # the shadow entry directly; `passwd -S` proved unreliable here
        machine.succeed("grep -q '^root:!:' /etc/shadow")

    with subtest("toolchain on PATH"):
        machine.succeed("rustc --version")
        machine.succeed("cargo --version")
        machine.succeed("nvim --version")

    with subtest("identity"):
        machine.succeed("hostname | grep -qx thinkpad")
  '';
}
