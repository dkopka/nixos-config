{ inputs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix

    inputs.nixos-hardware.nixosModules.common-cpu-intel  # microcode, KVM, i915
    inputs.nixos-hardware.nixosModules.common-pc-ssd     # fstrim, scheduler

    ../../modules/boot.nix
    ../../modules/core.nix
    ../../modules/docker.nix
    ../../modules/networking.nix
    ../../modules/services.nix
    ../../modules/ssh.nix
    ../../modules/users.nix
  ];

  networking.hostName = "thinkpad";
  boot.initrd.availableKernelModules = [ "e1000e" ];

  # Never change this after install — it pins stateful-data migration behaviour,
  # not the package versions (those come from flake.lock).
  system.stateVersion = "26.05";
}
