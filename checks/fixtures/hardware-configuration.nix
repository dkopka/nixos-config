# FIXTURE — stand-in for private/hardware-configuration.nix in tests/CI.
# Mirrors the real file's shape (LVM-on-LUKS mounts, intel laptop) with DUMMY
# identifiers. Never used on real hardware; safe to commit publicly.
{ config, lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/mapper/nixos-root";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/0000-0000";   # DUMMY
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/nix" =
    { device = "/dev/mapper/nixos-nix";
      fsType = "ext4";
    };

  fileSystems."/var" =
    { device = "/dev/mapper/nixos-var";
      fsType = "ext4";
    };

  fileSystems."/home" =
    { device = "/dev/mapper/nixos-home";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/mapper/nixos-swap"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
