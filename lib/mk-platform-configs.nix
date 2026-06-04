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
  # For nixos-rebuild on the board (native aarch64).
  mkPlatformConfigs =
    platform:
    lib.mapAttrs (
      _name: targetModule: mkNixosSystem platform targetModule platform.system
    ) platform.targets;

  mkSdImage =
    platform: targetName: buildSystem:
    (mkNixosSystem platform platform.targets.${targetName} buildSystem).config.system.build.sdImage;
}
