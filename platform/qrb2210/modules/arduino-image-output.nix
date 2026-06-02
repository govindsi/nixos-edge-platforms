# Produce an Arduino/Armbian-style flash bundle alongside the NixOS SD .img.
# for use with https://github.com/arduino/arduino-flasher-cli
{
  config,
  lib,
  pkgs,
  ...
}:

let
  qcombin = pkgs.qrb2210-qcombin;
  boot = pkgs.qrb2210-boot;
in
{
  sdImage.postBuildCommands = lib.mkAfter ''
    arduino_dir=$(mktemp -d)
    mkdir -p "$arduino_dir/arduino-images/flash"
    cp -a ${qcombin}/share/qcombin/Agatti/arduino-uno-q/. "$arduino_dir/arduino-images/flash/"
    chmod -R u+w "$arduino_dir/arduino-images/flash"
    cp -f ${qcombin}/share/qcombin/Agatti/prog_firehose_ddr.elf "$arduino_dir/arduino-images/flash/"
    cp -f ${boot}/boot.img "$arduino_dir/arduino-images/flash/boot.img"

    eval $(partx "$img" -o START,SECTORS --nr 1 --pairs)
    dd if="$img" of="$arduino_dir/arduino-images/disk-sdcard.img.esp" bs=512 skip="$START" count="$SECTORS" status=none

    eval $(partx "$img" -o START,SECTORS --nr 2 --pairs)
    dd if="$img" of="$arduino_dir/arduino-images/disk-sdcard.img.root" bs=512 skip="$START" count="$SECTORS" status=none

    tar -cf "$out/${config.image.baseName}-arduino-flash.tar" -C "$arduino_dir" arduino-images
    rm -rf "$arduino_dir"
  '';
}
