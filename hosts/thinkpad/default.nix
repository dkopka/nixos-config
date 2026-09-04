{
  imports = [
    ./common.nix

    ../../private/hardware-configuration.nix
    ../../private/luks.nix

    modules = [
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-intel-gen2
    ];
  ];
}
