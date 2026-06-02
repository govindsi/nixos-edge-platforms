{
  description = "NixOS images for embedded platforms (UNO Q, future NXP, …)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "path:../nixos-hardware";
  };

  outputs = inputs@{ nixpkgs, nixos-hardware, ... }:
    let
      lib = nixpkgs.lib;
      mkPlatformConfigs = import ./lib/mk-platform-configs.nix { inherit nixpkgs; };
      qrb2210 = import ./platform/qrb2210 { inherit lib nixos-hardware; };
    in
    {
      nixosConfigurations = mkPlatformConfigs qrb2210;
    };
}
