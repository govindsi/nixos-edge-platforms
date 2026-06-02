# Arduino UNO Q host configuration (image-oriented defaults).
{ config, pkgs, ... }:

{
  system.stateVersion = "25.05";

  # Used when building the ext4 root partition in the image
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  networking.hostName = "arduino-uno-q";
  time.timeZone = "UTC";

  users.users.root = {
    # Change before flashing
    password = "nixos";
  };

  services.openssh.enable = true;

  # USB ADB shell from host (nix-shell -p android-tools; adb devices / adb shell)
  hardware.qrb2210.adb.enable = true;
  hardware.qrb2210.resizeRootfs.enable = true;

  # Optional: more store space in the image
  # image.additionalSpace = "2G";
}
