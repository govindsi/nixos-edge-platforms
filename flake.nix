{
  description = "NixOS images for embedded platforms (UNO Q, future NXP, …)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # QRB2210 modules are not on github:NixOS/nixos-hardware master yet.
    nixos-hardware.url = "path:../nixos-hardware";
  };

  outputs = inputs@{ nixpkgs, nixos-hardware, ... }:
    let
      lib = nixpkgs.lib;
      mkPlatformConfigs = import ./lib/mk-platform-configs.nix { inherit nixpkgs; };

      qrb2210 = import ./platform/qrb2210 {
        inherit lib nixos-hardware;
      };

      # nxp = import ./platform/nxp { inherit lib nixos-hardware; };
    in
    {
      # Add more platforms: nixosConfigurations = mkPlatformConfigs qrb2210 // mkPlatformConfigs nxp;
      nixosConfigurations = mkPlatformConfigs qrb2210;

      packages = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.writeShellScriptBin "unoQ-help" ''
            echo "Build SD image: nix build .#nixosConfigurations.arduino-uno-q.config.system.build.sdImage"
            echo "Platforms: platform/qrb2210 (Arduino UNO Q), platform/nxp (planned)"
          '';
        }
      );
    };
}
