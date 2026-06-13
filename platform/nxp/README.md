# NXP platforms

Board-specific image flakes live in subdirectories (same pattern as `platform/qrb2210/`).

| Board | Path | nixos-hardware module |
| ----- | ------ | --------------------- |
| i.MX8M Plus EVK | [imx8mp-evk](./imx8mp-evk/) | `nxp-imx8mp-evk` |
| i.MX93 EVK | [imx93-evk](./imx93-evk/) | `nxp-imx93-evk` |
| MaaXBoard 8ULP | [maaxboard-8ulp](./maaxboard-8ulp/) | `nxp-maaxboard-8ulp` |

Shared i.MX9x helpers: [imx9/](./imx9/) (`make-ext4-fs.nix`, `sd-image.nix`). CompuLab UCM-i.MX95: [../compulab/ucm-imx95/](../compulab/ucm-imx95/).

## Build (i.MX8M Plus EVK)

```bash
nix build .#packages.x86_64-linux.imx8mp-evk-sd-image
# or
nix build .#packages.aarch64-linux.imx8mp-evk-sd-image
```

Flash firmware (32 KiB offset):

```bash
sudo dd if=./result/image/flash.bin of=/dev/sdX bs=1k seek=32 conv=fsync
```

## Build (i.MX93 EVK)

```bash
nix build .#packages.x86_64-linux.imx93-evk-sd-image
# or
nix build .#packages.aarch64-linux.imx93-evk-sd-image
```

Flash firmware (32 KiB offset, same as i.MX8MP):

```bash
sudo dd if=./result/flash.bin of=/dev/sdX bs=1k seek=32 conv=fsync
# or from the image output:
sudo dd if=./result/boot.img of=/dev/sdX bs=1k seek=32 conv=fsync
```

## Build (MaaXBoard 8ULP)

```bash
nix build .#packages.x86_64-linux.maaxboard-8ulp-sd-image
# or
nix build .#packages.aarch64-linux.maaxboard-8ulp-sd-image
```

Flash firmware (32 KiB offset):

```bash
sudo dd if=./result/flash.bin of=/dev/sdX bs=1k seek=32 conv=fsync
```

Serial console: `ttyLP1` @ 115200.

`nixosConfigurations.<target>` is for on-device `nixos-rebuild`, not for producing the SD image packages.
