# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# NXP i.MX93 EVK
{ lib, nixos-hardware }:
{
  system = "aarch64-linux";

  overlays = [ ];

  modules = [
    nixos-hardware.nixosModules.nxp-imx93-evk
    ./modules/cross.nix
    ./modules/sd-image.nix
  ];

  targets = {
    imx93-evk = import ./target/imx93-evk.nix;
  };
}
