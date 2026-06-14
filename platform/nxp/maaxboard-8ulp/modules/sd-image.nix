# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# Avnet MaaXBoard 8ULP image: flash.bin @ sector 66, VFAT /boot + ext4 root (Yocto layout).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  rootfsImage = pkgs.callPackage ../../imx9/make-ext4-fs.nix {
    inherit (config.sdImage) storePaths;
    compressImage = config.sdImage.compressImage;
    populateImageCommands = config.sdImage.populateRootCommands;
    volumeLabel = "NIXOS_SD";
  };

  system = config.system.build.toplevel;
  uEnvTxt = pkgs.writeText "maaxboard-8ulp-uEnv.txt" ''
    fdt_file=maaxboard-8ulp.dtb
    fdt_addr_r=0x84000000
    fdt_addr=0x84000000
    ramdisk_addr_r=0x85000000
    initrd=initrd
    loadinitrd=fatload mmc ''${mmcdev}:''${mmcpart} ''${ramdisk_addr_r} ''${initrd}
    boot_os=run loadinitrd; booti ''${loadaddr} ''${ramdisk_addr_r}:''${filesize} ''${fdt_addr_r}
    console=ttyLP1,115200 console=tty1
    mmcargs=setenv bootargs console=''${console} root=''${mmcroot} rootwait rw init=${system}/init ${lib.removeSuffix "\n" (builtins.readFile "${system}/kernel-params")}
  '';

  bootSizeMb = 100;
  ubootReservedMb = 10;
  sectorSize = 512;
  ubootOffsetSector = 66;
  fatStartSector = ubootReservedMb * 1024 * 1024 / sectorSize;
  fatSizeSector = bootSizeMb * 1024 * 1024 / sectorSize;
in
{
  imports = [ ../../imx9/sd-image.nix ];
  _module.args.target = "maaxboard-8ulp";

  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "ext4"
  ];

  sdImage = {
    imageName = lib.mkDefault "nixos_maaxboard-8ulp.img";
    compressImage = false;

    populateFirmwareCommands = lib.mkOverride 50 ''
      cp ${pkgs.maaxboard-8ulp-boot}/image/flash.bin firmware/flash.bin
      chmod 0644 firmware/flash.bin

      mkdir -p firmware/boot
      gen=$(readlink -f ${system})
      cp -L "$gen/kernel" firmware/boot/Image
      cp -L "$gen/initrd" firmware/boot/initrd
      cp -L "$gen/dtbs/freescale/maaxboard-8ulp.dtb" firmware/boot/maaxboard-8ulp.dtb
      cp ${uEnvTxt} firmware/boot/uEnv.txt
    '';

    populateRootCommands = lib.mkOverride 50 ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot

      dtbPath=$(echo ./files/boot/nixos/*-dtbs-filtered)
      chmod +w $dtbPath
      cd ./files/boot/nixos
      ln -s ./*dtbs-filtered ./dtbs-filtered
      cd /
    '';

    postBuildCommands = lib.mkOverride 50 ''
      dd if=firmware/flash.bin of=$img bs=512 seek=${toString ubootOffsetSector} conv=notrunc,sync
      mkdir -p $out
      cp firmware/flash.bin $out/flash.bin
    '';

    imageBuildCommands = lib.mkOverride 50 ''
      mkdir -p $out/nix-support
      export img=$out/${config.sdImage.imageName}
      echo "${pkgs.stdenv.hostPlatform.system}" > $out/nix-support/system
      echo "file sd-image $img" >> $out/nix-support/hydra-build-products

      root_fs=${rootfsImage}
      rootsize=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
      rootStart=$(( ${toString fatStartSector} + ${toString fatSizeSector} ))
      imagesize=$(((rootStart + rootsize) * ${toString sectorSize}))
      truncate -s $imagesize $img

      sfdisk --no-reread --no-tell-kernel $img <<EOF
          label: dos
          label-id: 0x2178694e
          unit: sectors
          sector-size: 512

          start=${toString fatStartSector}, size=${toString fatSizeSector}, type=c
          start=$rootStart, size=$rootsize, type=83, bootable
      EOF

      bootfs=boot-fs.img
      # mkfs.vfat -C size is in KiB (not bytes).
      mkfs.vfat -n NIXOS_BOOT -S 512 -C $bootfs $(( ${toString bootSizeMb} * 1024 ))
      mcopy -i $bootfs firmware/boot/Image ::Image
      mcopy -i $bootfs firmware/boot/initrd ::initrd
      mcopy -i $bootfs firmware/boot/maaxboard-8ulp.dtb ::maaxboard-8ulp.dtb
      mcopy -i $bootfs firmware/boot/uEnv.txt ::uEnv.txt

      eval $(partx $img -o START,SECTORS --nr 1 --pairs)
      dd conv=notrunc if=$bootfs of=$img seek=$START count=$SECTORS

      eval $(partx $img -o START,SECTORS --nr 2 --pairs)
      dd conv=notrunc if=$root_fs of=$img seek=$START count=$SECTORS

      ${config.sdImage.postBuildCommands}

      cp firmware/flash.bin $out/boot.img
    '';
  };
}
