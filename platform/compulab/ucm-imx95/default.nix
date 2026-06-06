# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# CompuLab UCM-i.MX95 Evaluation Kit
{ lib, nixos-hardware }:
{
  system = "aarch64-linux";

  overlays = [ ];

  modules = [
    nixos-hardware.nixosModules.ucm-imx95
    ./modules/cross.nix
    ./modules/sd-image.nix
  ];

  targets = {
    ucm-imx95 = import ./target/ucm-imx95.nix;
  };
}
