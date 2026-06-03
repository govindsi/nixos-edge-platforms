# Build nixosConfigurations from a platform descriptor (see platform/*/default.nix).
{ nixpkgs }:

platform:
let
  inherit (nixpkgs) lib;
in
lib.mapAttrs (
  _name: targetModule:
  lib.nixosSystem {
    system = platform.system;
    specialArgs = platform.specialArgs or { };
    modules = platform.modules ++ [
      (
        { ... }:
        {
          nixpkgs.overlays = platform.overlays;
        }
      )
      targetModule
    ];
  }
) platform.targets
