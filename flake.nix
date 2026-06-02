{
  description = "NixOS images for embedded platforms (UNO Q, future NXP, …)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "path:../nixos-hardware";
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      _mkPlatformConfigs = import ./lib/mk-platform-configs.nix { inherit nixpkgs; };
    in
    {
      nixosConfigurations = { };
    };
}
