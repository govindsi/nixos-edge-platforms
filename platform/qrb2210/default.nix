# QRB2210 / Qualcomm boards (Arduino UNO Q, etc.)
{ lib, nixos-hardware }:
{
  system = "aarch64-linux";
  specialArgs.buildSystem = "x86_64-linux";

  overlays = [
    (import ./overlay.nix)
  ];

  modules = [
    nixos-hardware.nixosModules.arduino-uno-q
    ./modules/adb.nix
    ./modules/resize-rootfs.nix
    ./modules/sd-image.nix
    ./modules/arduino-image-output.nix
  ];

  machines = {
    arduino-uno-q = import ./machines/arduino-uno-q.nix;
  };
}
