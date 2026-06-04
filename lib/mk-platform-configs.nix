# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# Build nixosConfigurations from a platform descriptor (see platform/*/default.nix).
{ nixpkgs }:

let
  inherit (nixpkgs) lib;

  mkNixosSystem =
    platform: targetModule: buildSystem:
    lib.nixosSystem {
      system = platform.system;
      specialArgs = (platform.specialArgs or { }) // {
        inherit buildSystem;
      };
      modules = platform.modules ++ [
        (
          { ... }:
          {
            nixpkgs.overlays = platform.overlays;
          }
        )
        targetModule
      ];
    };
in
{
  mkPlatformConfigs =
    platform:
    lib.mapAttrs (
      _name: targetModule: mkNixosSystem platform targetModule platform.system
    ) platform.targets;

  mkSdImage =
    platform: targetName: buildSystem:
    (mkNixosSystem platform platform.targets.${targetName} buildSystem).config.system.build.sdImage;
}
