# NXP i.MX8M Plus EVK
{ lib, nixos-hardware }:
{
  system = "aarch64-linux";

  overlays = [ ];

  modules = [
    nixos-hardware.nixosModules.nxp-imx8mp-evk
    ./modules/cross.nix
    ./modules/sd-image.nix
  ];

  targets = {
    imx8mp-evk = import ./target/imx8mp-evk.nix;
  };
}
