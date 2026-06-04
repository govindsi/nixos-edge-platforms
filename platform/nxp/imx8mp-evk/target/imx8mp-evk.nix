# i.MX8M Plus EVK host configuration (SD image / on-device rebuild).
{ config, lib, ... }:

{
  system.stateVersion = "25.05";

  boot = {
    kernelParams = lib.mkForce [ "root=/dev/mmcblk0p2" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    initrd.systemd.tpm2.enable = false;
  };

  hardware = {
    deviceTree.name = lib.mkForce "freescale/imx8mp-evk.dtb";
    enableAllHardware = lib.mkForce false;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  networking.hostName = "imx8mp-evk";
  time.timeZone = "UTC";

  users.users.root.password = "nixos";

  services.openssh.enable = true;
}
