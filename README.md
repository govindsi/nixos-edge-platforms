# Edge Computing NixOS

Consumer flake for building NixOS images on embedded boards. Hardware BSP and profiles live in [nixos-hardware](../nixos-hardware); this repo adds image layout, board-specific services, and machine configs.

## Layout

```
flake.nix                 # inputs + platform registry
lib/mk-platform-configs.nix
platform/
  qrb2210/                # Qualcomm QRB2210 (Arduino UNO Q)
    default.nix           # system, overlays, modules, machines
    overlay.nix
    bsp/                  # packages not in nixos-hardware (e.g. adbd)
    modules/              # sd-image, adb, resize-rootfs, …
    machines/             # per-product host config
  nxp/                    # placeholder for future NXP boards
```

## Build

```bash
nix build .#nixosConfigurations.arduino-uno-q.config.system.build.sdImage
```

Outputs: `*.img.zst` and `*-arduino-flash.tar` for [arduino-flasher-cli](https://github.com/arduino/arduino-flasher-cli).

Default root password is `nixos` — change in `platform/qrb2210/machines/arduino-uno-q.nix` before flashing.

## Adding a platform

```
1. Add `platform/<name>/default.nix` with `system`, `overlays`, `modules`, and `machines`.
2. Import it in `flake.nix` and merge: `mkPlatformConfigs foo // mkPlatformConfigs bar`.

```
