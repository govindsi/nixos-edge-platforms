# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
{
  description = "NixOS images for embedded platforms (UNO Q, i.MX8M Plus / i.MX93 EVK, UCM-i.MX95, …)";

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
      inherit (import ./lib/mk-platform-configs.nix { inherit nixpkgs; })
        mkPlatformConfigs
        mkSdImage
        ;

      qrb2210 = import ./platform/qrb2210 {
        inherit lib;
        nixos-hardware = hardware;
      };

      imx8mp-evk = import ./platform/nxp/imx8mp-evk {
        inherit lib;
        nixos-hardware = hardware;
      };

      imx93-evk = import ./platform/nxp/imx93-evk {
        inherit lib;
        nixos-hardware = hardware;
      };

      maaxboard-8ulp = import ./platform/nxp/maaxboard-8ulp {
        inherit lib;
        nixos-hardware = hardware;
      };

      ucm-imx95 = import ./platform/compulab/ucm-imx95 {
        inherit lib;
        nixos-hardware = hardware;
      };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      nixosConfigurations =
        mkPlatformConfigs qrb2210
        // mkPlatformConfigs imx8mp-evk
        // mkPlatformConfigs imx93-evk
        // mkPlatformConfigs maaxboard-8ulp
        // mkPlatformConfigs ucm-imx95;

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

      packages = lib.genAttrs systems (buildSystem: {
        arduino-uno-q-sd-image = mkSdImage qrb2210 "arduino-uno-q" buildSystem;
        imx8mp-evk-sd-image = mkSdImage imx8mp-evk "imx8mp-evk" buildSystem;
        imx93-evk-sd-image = mkSdImage imx93-evk "imx93-evk" buildSystem;
        maaxboard-8ulp-sd-image = mkSdImage maaxboard-8ulp "maaxboard-8ulp" buildSystem;
        ucm-imx95-sd-image = mkSdImage ucm-imx95 "ucm-imx95" buildSystem;
      });
    };
}
