# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# i.MX9x SD image (flash.bin @ 32 KiB + ext4 root), ported from ghaf imx9x-sdimage.nix.
{
  config,
  pkgs,
  lib,
  target ? "imx95",
  ...
}:
let
  imxBootAttr = "${target}-boot";
  imxBootPkg =
    if builtins.hasAttr imxBootAttr pkgs then
      builtins.getAttr imxBootAttr pkgs
    else
      pkgs.imx95-boot;

  imxLabel = "i.MX${lib.removePrefix "imx" target}";

  rootfsImage = pkgs.callPackage ./make-ext4-fs.nix {
    inherit (config.sdImage) storePaths;
    compressImage = config.sdImage.compressImage;
    populateImageCommands = config.sdImage.populateRootCommands;
    volumeLabel = "NIXOS_SD";
  };
in
{
  options.sdImage = {
    imageName = lib.mkOption {
      type = lib.types.str;
      default = "nixos_${target}.img";
      description = "Name of the generated SD image file.";
    };

    storePaths = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      description = "Derivations included in the Nix store on the SD image.";
    };

    rootfsLabelPath = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-label/NIXOS_SD";
      description = "Root filesystem device for the running system.";
    };

    populateFirmwareCommands = lib.mkOption {
      type = lib.types.str;
      default = ''
        cp ${imxBootPkg}/image/flash.bin .
        chmod 0644 flash.bin
        mv flash.bin firmware
      '';
    };

    populateRootCommands = lib.mkOption {
      type = lib.types.str;
      default = ''
        mkdir -p ./files/boot
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot

        dtbPath=$(echo ./files/boot/nixos/*-dtbs-filtered)
        chmod +w $dtbPath
        cd ./files/boot/nixos
        ln -s ./*dtbs-filtered ./dtbs-filtered
        cd /
      '';
    };

    postBootCommands = lib.mkOption {
      type = lib.types.str;
      default = ''
        if [ -f ${config.sdImage.nixPathRegistrationFile} ]; then
          set -euo pipefail
          rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
          bootDevice=$(lsblk -npo PKNAME $rootPart)
          partNum=1
          echo ",+," | sfdisk -N$partNum --no-reread $bootDevice
          ${pkgs.parted}/bin/partprobe
          ${pkgs.e2fsprogs}/bin/resize2fs $rootPart
          ${config.nix.package.out}/bin/nix-store --load-db < ${config.sdImage.nixPathRegistrationFile}
          touch /etc/NIXOS
          ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
          rm -f ${config.sdImage.nixPathRegistrationFile}
        fi
      '';
    };

    postBuildCommands = lib.mkOption {
      type = lib.types.str;
      default = ''
        echo "Writing flash.bin for ${imxLabel} BootROM..."
        dd if=firmware/flash.bin of=$img bs=1K seek=32 conv=notrunc,sync
        mkdir -p $out
        hexdump -C -n 512 -s $((32*1024)) $img > $out/flashbin-dump.txt
        cp firmware/flash.bin $out/flash.bin
      '';
    };

    imageBuildCommands = lib.mkOption {
      type = lib.types.str;
      default = ''
        mkdir -p $out/nix-support
        export img=$out/${config.sdImage.imageName}
        echo "${pkgs.stdenv.hostPlatform.system}" > $out/nix-support/system
        if test -n "$compressImage"; then
          echo "file sd-image $img.zst" >> $out/nix-support/hydra-build-products
        else
          echo "file sd-image $img" >> $out/nix-support/hydra-build-products
        fi

        root_fs=${rootfsImage}
        ${lib.optionalString config.sdImage.compressImage ''
          root_fs=./root-fs.img
          zstd -d --no-progress "${rootfsImage}" -o $root_fs
        ''}

        rootsize=$(du -B 512 --apparent-size $root_fs | awk '{ print $1 }')
        blocksize=512
        rootoffset=8192
        imagesize=$(((rootoffset + rootsize)*blocksize))
        truncate -s $imagesize $img

        sfdisk --no-reread --no-tell-kernel $img <<EOF
            label: dos
            label-id: 0x2178694e
            unit: sectors
            sector-size: 512

            start=$rootoffset, size=$rootsize, type=83, bootable
        EOF

        mkdir -p firmware
        ${config.sdImage.populateFirmwareCommands}

        eval $(partx $img -o START,SECTORS --nr 1 --pairs)
        dd conv=notrunc if=$root_fs of=$img seek=$START count=$SECTORS

        ${config.sdImage.postBuildCommands}

        if test -n "$compressImage"; then
          zstd -T$NIX_BUILD_CORES --rm $img
        fi

        cp firmware/flash.bin $out/boot.img
      '';
    };

    compressImage = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    nixPathRegistrationFile = lib.mkOption {
      type = lib.types.str;
      default = "/nix-path-registration";
    };
  };

  config = {
    fileSystems."/" = {
      device = config.sdImage.rootfsLabelPath;
      fsType = "ext4";
    };

    sdImage = {
      storePaths = [ config.system.build.toplevel ];
      compressImage = false;
    };

    system.build.sdImage = pkgs.stdenv.mkDerivation {
      name = config.sdImage.imageName;
      compressImage = config.sdImage.compressImage;
      nativeBuildInputs = with pkgs; [
        dosfstools
        e2fsprogs
        mtools
        libfaketime
        util-linux
        zstd
      ];
      buildCommand = ''
        mkdir firmware
        ${config.sdImage.populateFirmwareCommands}
        ${config.sdImage.imageBuildCommands}
      '';
    };

    boot.postBootCommands = config.sdImage.postBootCommands;
  };
}
