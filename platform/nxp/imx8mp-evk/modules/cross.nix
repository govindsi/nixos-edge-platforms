# Cross-build aarch64 NixOS images on x86_64 (buildSystem from specialArgs).
{
  lib,
  buildSystem ? (if builtins ? currentSystem then builtins.currentSystem else null),
  ...
}:

let
  enableCross = buildSystem != null && buildSystem != "aarch64-linux";
in
{
  nixpkgs.buildPlatform = lib.mkIf enableCross {
    system = buildSystem;
  };
}
