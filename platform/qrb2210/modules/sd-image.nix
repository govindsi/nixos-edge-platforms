{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    # Base sd-image module.
    "${modulesPath}/installer/sd-card/sd-image.nix"
    # Extra output tarball for arduino-flasher-cli.
    ./arduino-image-output.nix
  ];

  # nixpkgs sd-image sets `hardware.enableAllHardware = true`, which can pull in
  # filesystems we don't need.
  hardware.enableAllHardware = lib.mkForce false;

  # SD image only needs vfat + ext4.
  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "ext4"
  ];

  # Avoid merging with sd-image defaults (duplicate label / "sd-card" in name).
  image.baseName = lib.mkForce "nixos-arduino-uno-q-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

  # Generic sd-image grow (sfdisk on MBR p2) is wrong for eMMC GPT root on p68.
  sdImage.expandOnBoot = false;

  sdImage = {
    firmwareSize = lib.mkDefault 512;
    populateFirmwareCommands = ''
      mkdir -p firmware/flash

      cp -a ${pkgs.qrb2210-qcombin}/share/qcombin/Agatti/. firmware/flash/
      chmod -R u+w firmware/flash
      cp ${pkgs.qrb2210-boot}/boot.img firmware/flash/boot.img
      cp ${pkgs.qrb2210-boot}/boot.scr firmware/boot.scr
      cp ${pkgs.qrb2210-boot}/boot.cmd firmware/boot.cmd
      cp ${pkgs.qrb2210-boot}/qrb2210Env.txt firmware/qrb2210Env.txt

      # U-Boot loads from mmc 0:43 (this FAT), not ext4 /boot on p68.
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./firmware
      gen=$(readlink -f ${config.system.build.toplevel})
      cp -L "$gen/kernel" ./firmware/Image
      cp -L "$gen/initrd" ./firmware/initrd
      mkdir -p ./firmware/dtbs
      cp -a "$gen/dtbs/." ./firmware/dtbs/
    '';

    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot

      cp ${pkgs.qrb2210-boot}/boot.scr ./files/boot/boot.scr
      cp ${pkgs.qrb2210-boot}/boot.cmd ./files/boot/boot.cmd
      cp ${pkgs.qrb2210-boot}/qrb2210Env.txt ./files/boot/qrb2210Env.txt
    '';
  };
}
