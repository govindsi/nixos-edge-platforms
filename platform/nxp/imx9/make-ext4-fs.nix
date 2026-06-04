# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# Builds a sized ext4 root filesystem image with a Nix store closure.
{
  pkgs,
  lib,
  storePaths,
  compressImage ? false,
  populateImageCommands ? "",
  volumeLabel,
  uuid ? "44444444-4444-4444-8888-888888888888",
  ...
}:
let
  sdClosureInfo = pkgs.buildPackages.closureInfo { rootPaths = storePaths; };
  remove_kernel_dup = ''
    if [[ $in == *"linux-"*"-unknown-linux-gnu-"*"-hardened1"* ]]; then
      if [ -e $in/Image ]; then
        chmod -R +w ./rootImage/$in
        rm ./rootImage/$in/Image
        rm -r ./rootImage/$in/dtbs
        chmod -R -w ./rootImage/$in
      fi
      if [ -e $in/initrd ]; then
        chmod -R +w ./rootImage/$in
        rm ./rootImage/$in/initrd*
        chmod -R -w ./rootImage/$in
      fi
    fi
  '';
in
pkgs.stdenv.mkDerivation {
  name = "ext4-fs.img${lib.optionalString compressImage ".zst"}";

  nativeBuildInputs =
    with pkgs;
    [
      e2fsprogs
      libfaketime
      perl
      fakeroot
    ]
    ++ lib.optional compressImage zstd;

  buildCommand = ''
    ${
      if compressImage then
        "img=temp.img"
      else
        "img=$out"
    }
    (
      mkdir -p ./files
      ${populateImageCommands}
    )

    mkdir -p ./rootImage/nix/store

    while read in; do
      cp -a --reflink=auto $in -t ./rootImage/nix/store/
      ${remove_kernel_dup}
      if [[ $in == *"linux-headers-"* ]]; then
        chmod -R +w ./rootImage/$in
        rm -r ./rootImage/$in
      fi
      if [[ $in == *"source" ]]; then
        chmod -R +w ./rootImage/$in
        rm -r ./rootImage/$in
      fi
    done < ${sdClosureInfo}/store-paths

    (
      GLOBIGNORE=".:.."
      shopt -u dotglob
      for f in ./files/*; do
        cp -a --reflink=auto -t ./rootImage/ "$f"
      done
    )

    cp ${sdClosureInfo}/registration ./rootImage/nix-path-registration

    numInodes=$(find ./rootImage | wc -l)
    numDataBlocks=$(du -s -c -B 4096 --apparent-size ./rootImage | tail -1 | awk '{ print int($1 * 1.20) }')
    bytes=$((2 * 4096 * numInodes + 4096 * numDataBlocks))
    mebibyte=$((1024 * 1024))
    if (( bytes % mebibyte )); then
      bytes=$(( (bytes / mebibyte + 1) * mebibyte ))
    fi

    truncate -s $bytes $img
    faketime -f "1970-01-01 00:00:01" fakeroot mkfs.ext4 -L ${volumeLabel} -U ${uuid} -d ./rootImage $img

    export EXT2FS_NO_MTAB_OK=yes
    fsck.ext4 -n -f $img
    resize2fs -M $img
    new_size=$(dumpe2fs -h $img | awk -F: '/Block count/{count=$2} /Block size/{size=$2} END{print (count*size+16*2**20)/size}')
    resize2fs $img $new_size

    ${
      if compressImage then
        ''
          zstd -T$NIX_BUILD_CORES -v --no-progress ./$img -o $out
        ''
      else
        ""
    }
  '';
}
