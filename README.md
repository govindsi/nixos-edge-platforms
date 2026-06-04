# Edge Computing NixOS

Consumer flake for building NixOS images on embedded boards. Hardware BSP and profiles live in [nixos-hardware](../nixos-hardware); this repo adds image layout, board-specific services, and machine configs.

## Layout

```
flake.nix                 # inputs + platform registry
lib/mk-platform-configs.nix
platform/
  qrb2210/                # Qualcomm QRB2210 (Arduino UNO Q)
    default.nix           # system, overlays, modules, targets
    overlay.nix
    packages/             # local packages not in nixos-hardware (e.g. adbd)
    modules/              # sd-image, adb, resize-rootfs, …
    target/               # per-product host config
  nxp/                    # placeholder for future NXP boards
```

## Build

List SD image targets:

```bash
nix flake show
```

| Builder machine | Command |
|-----------------|---------|
| `aarch64-linux` | `nix build .#packages.aarch64-linux.arduino-uno-q-sd-image` |
| `x86_64-linux` (cross) | `nix build .#packages.x86_64-linux.arduino-uno-q-sd-image` |

Outputs: `*.img.zst` and `*-arduino-flash.tar` for [arduino-flasher-cli](https://github.com/arduino/arduino-flasher-cli).

`nixosConfigurations.arduino-uno-q` is for **on-device** `nixos-rebuild`, not for building the SD image.

Default root password is `nixos` — change in `platform/qrb2210/target/arduino-uno-q.nix` before flashing.

## Adding a platform

```
1. Add `platform/<name>/default.nix` with `system`, `overlays`, `modules`, and `targets`.
2. Import it in `flake.nix` and merge: `mkPlatformConfigs foo // mkPlatformConfigs bar`.
3. Add `packages.<buildSystem>.<name>-sd-image` entries in `flake.nix` for each builder you support.

```
