# hardware.nix is nixos-generate-config output ("do not modify"), and that
# tool never emits LUKS config. Without it the initrd has no reason to
# know /dev/mapper/nixos-root et al. sit behind LUKS, and boot fails.
{
  boot.initrd.luks.devices."crypted" = {
    # /dev/nvme0n1p2
    device = "/dev/disk/by-uuid/08de1afa-5d75-4615-90f4-7ff710ac316b";
    allowDiscards = true;    # pass TRIM through LUKS — keeps SSD performance
    bypassWorkqueues = true; # lower latency through dm-crypt on NVMe
  };
}
