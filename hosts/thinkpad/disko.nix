{ inputs, ... }:
let
  ext4 = mountpoint: { type = "filesystem"; format = "ext4"; inherit mountpoint; };
in
{
  imports = [inputs.disko.nixosModules.disko ];
  # FIXME: We run this on existing system that doesn't
  # require disko configuration. Change to 'true' for
  # fresh installs.
  disko.enableConfig = false;
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "fmask=0077" "dmask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings.allowDiscards = true;
              content = { type = "lvm_pv"; vg = "nixos"; };
            };
          };
        };
      };
    };

    lvm_vg.nixos = {
      type = "lvm_vg";
      lvs = {
        swap = { size = "32G";  content = { type = "swap"; resumeDevice = true; }; };
        root = { size = "60G";  content = ext4 "/"; };
        nix  = { size = "260G"; content = ext4 "/nix"; };
        var  = { size = "150G"; content = ext4 "/var"; };
        home = { size = "100%FREE"; content = ext4 "/home"; };
      };
    };
  };
}
