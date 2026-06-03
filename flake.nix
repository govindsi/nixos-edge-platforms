{
  description = "NixOS images for embedded platforms (UNO Q, future NXP, …)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # QRB2210 modules are not on github:NixOS/nixos-hardware master yet.
    # Input must not be named "nixos-hardware": Nix 2.34 treats that as a store path on lock/update.
    hardware.url = "git+file:../nixos-hardware";
  };

  outputs =
    inputs@{ nixpkgs, hardware, ... }:
    let
      lib = nixpkgs.lib;
      mkPlatformConfigs = import ./lib/mk-platform-configs.nix { inherit nixpkgs; };

      qrb2210 = import ./platform/qrb2210 {
        inherit lib;
        nixos-hardware = hardware;
      };

      # nxp = import ./platform/nxp { inherit lib; nixos-hardware = hardware; };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      # Add more platforms: nixosConfigurations = mkPlatformConfigs qrb2210 // mkPlatformConfigs nxp;
      nixosConfigurations = mkPlatformConfigs qrb2210;

      # Plain nixfmt with no args reads stdin forever; nix fmt does not pass files.
      formatter = lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellScriptBin "nixfmt" ''
          set -euo pipefail
          cd "''${PRJ_ROOT:-$PWD}"
          if [ "$#" -gt 0 ]; then
            exec ${pkgs.nixfmt}/bin/nixfmt "$@"
          fi
          git ls-files '*.nix' | while read -r f; do [ -f "$f" ] && printf '%s\0' "$f"; done \
            | xargs -0 -r ${pkgs.nixfmt}/bin/nixfmt
        ''
      );

      packages = lib.genAttrs systems (
        system:
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
