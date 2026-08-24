# FIXTURE — stand-in for private/luks.nix in tests/CI. DUMMY UUID.
# Exercises the same option paths (initrd includes cryptsetup, dm-crypt) so a
# build catches errors here; the device only has to exist at boot on real HW.
{
  boot.initrd.luks.devices."crypted" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";  # DUMMY
    allowDiscards = true;
    bypassWorkqueues = true;
  };
}
