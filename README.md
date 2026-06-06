# unoQ

Consumer flake for building NixOS SD images on embedded boards. Hardware BSP and profiles live in [nixos-hardware](../nixos-hardware); this repo adds image layout, board-specific services, and machine configs.

Supported platforms:

| Platform | Board | Package |
| -------- | ----- | ------- |
| [qrb2210](./platform/qrb2210/) | Qualcomm QRB2210 (Arduino UNO Q) | `arduino-uno-q-sd-image` |
| [imx8mp-evk](./platform/nxp/imx8mp-evk/) | NXP i.MX8M Plus EVK | `imx8mp-evk-sd-image` |
| [imx93-evk](./platform/nxp/imx93-evk/) | NXP i.MX93 EVK | `imx93-evk-sd-image` |
| [ucm-imx95](./platform/compulab/ucm-imx95/) | CompuLab UCM-i.MX95 EVK | `ucm-imx95-sd-image` |

NXP flash notes: [platform/nxp/README.md](./platform/nxp/README.md). CompuLab: [platform/compulab/README.md](./platform/compulab/README.md).

## Layout

```
flake.nix                 # inputs + platform registry
lib/mk-platform-configs.nix
platform/
  qrb2210/                # Qualcomm QRB2210 (Arduino UNO Q)
    default.nix           # system, overlays, modules, targets
    overlay.nix
    packages/             # packages not in nixos-hardware (e.g. adbd)
    modules/              # sd-image, adb, resize-rootfs, …
    target/               # per-product host config
  nxp/
    imx8mp-evk/           # i.MX8M Plus EVK
    imx93-evk/            # i.MX93 EVK
    imx9/                 # shared helpers (make-ext4-fs.nix)
    README.md
  compulab/
    ucm-imx95/            # UCM-i.MX95 EVK
    README.md
```

## Inputs

```nix
hardware.url = "git+file:../nixos-hardware";
```

The input is named `hardware` (not `nixos-hardware`) to avoid Nix 2.34 store-path confusion on lock/update.

After changing nixos-hardware, refresh the lock:

```bash
nix flake lock --update-input hardware
```

## Build

Cross-build SD images from x86_64 (or build natively on aarch64):

```bash
# Arduino UNO Q
nix build .#packages.x86_64-linux.arduino-uno-q-sd-image

# NXP i.MX8M Plus EVK
nix build .#packages.x86_64-linux.imx8mp-evk-sd-image

# NXP i.MX93 EVK
nix build .#packages.x86_64-linux.imx93-evk-sd-image

# CompuLab UCM-i.MX95 EVK
nix build .#packages.x86_64-linux.ucm-imx95-sd-image
```

Equivalent via `nixosConfigurations` (same derivations):

```bash
nix build .#nixosConfigurations.arduino-uno-q.config.system.build.sdImage
nix build .#nixosConfigurations.imx8mp-evk.config.system.build.sdImage
nix build .#nixosConfigurations.imx93-evk.config.system.build.sdImage
nix build .#nixosConfigurations.ucm-imx95.config.system.build.sdImage
```

### Outputs

**Arduino UNO Q:** `result/` contains a compressed image and an Arduino flash bundle for [arduino-flasher-cli](https://github.com/arduino/arduino-flasher-cli) (`*-arduino-flash.tar`).

**NXP / CompuLab i.MX9x EVKs:** `result/` contains `nixos_*.img`, `flash.bin`, and `boot.img`. Write `flash.bin` to the SD card at a 32 KiB offset:

```bash
sudo dd if=./result/flash.bin of=/dev/sdX bs=1k seek=32 conv=fsync
```

Default root password is `nixos` — change in the platform `target/*.nix` before flashing.

## Adding a platform

1. Add `platform/<name>/default.nix` with `system`, `overlays`, `modules`, and `targets`.
2. Import it in `flake.nix` and merge: `mkPlatformConfigs foo // mkPlatformConfigs bar`.
3. Expose an SD image package: `mkSdImage foo "<target-name>" buildSystem` in `flake.nix` packages.

## Contributing

### Where changes go

| Change | Repository |
| ------ | ---------- |
| BSP (ATF, U-Boot, kernel, `nixosModules`, overlays) | [nixos-hardware](../nixos-hardware) |
| SD image layout, cross-build wiring, board services, flake packages | unoQ (this repo) |

Keep `hardware.url` pointing at your nixos-hardware checkout (`git+file:../nixos-hardware` by default). After BSP changes, refresh the lock from unoQ:

```bash
nix flake lock --update-input hardware
```

### Building and testing

Cross-build SD images from **x86_64** using the `packages.x86_64-linux.*-sd-image` attributes (see [Build](#build)). That is the supported developer workflow on a typical laptop.

`nixos-hardware` exposes some boot packages only under `packages.aarch64-linux` (native aarch64). Those do **not** build on x86_64 without a remote aarch64 builder — use unoQ for imx93/imx8mp image work from x86_64.

### Formatting

```bash
nix fmt
```

### Pull requests

1. Branch from `main` (or the active integration branch).
2. One logical change per commit; describe the **problem** in the commit body, not only the fix.
3. Confirm the relevant `nix build .#packages.x86_64-linux.<platform>-sd-image` succeeds.
4. If you changed nixos-hardware, mention the required `hardware` input revision or PR link.

### Git troubleshooting

If `.git` is owned by root (e.g. after `sudo nix` in the tree), fix ownership before committing or updating the lock:

```bash
sudo chown -R "$USER:$USER" .git
rm -rf .git && mv .git-local .git   # only if you use .git-local backup
```
