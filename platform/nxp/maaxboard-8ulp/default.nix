# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# Avnet MaaXBoard 8ULP (i.MX8ULP)
{ lib, nixos-hardware }:
{
  system = "aarch64-linux";

  overlays = [ ];

  modules = [
    nixos-hardware.nixosModules.nxp-maaxboard-8ulp
    ./modules/cross.nix
    ./modules/sd-image.nix
  ];

  targets = {
    maaxboard-8ulp = import ./target/maaxboard-8ulp.nix;
  };
}
