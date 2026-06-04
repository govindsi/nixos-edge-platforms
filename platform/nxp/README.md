# NXP platforms

Board-specific image flakes live in subdirectories (same pattern as `platform/qrb2210/`).

| Board | Path | nixos-hardware module |
| ----- | ------ | --------------------- |
| i.MX8M Plus EVK | [imx8mp-evk](./imx8mp-evk/) | `nxp-imx8mp-evk` |

## Build (i.MX8M Plus EVK)

```bash
nix build .#packages.x86_64-linux.imx8mp-evk-sd-image   # cross from ThinkPad
# or
nix build .#packages.aarch64-linux.imx8mp-evk-sd-image
```

Flash firmware (32 KiB offset per nixos-hardware docs):

```bash
sudo dd if=./result/image/flash.bin of=/dev/sdX bs=1k seek=32 conv=fsync
```

`nixosConfigurations.imx8mp-evk` is for on-device `nixos-rebuild`, not for producing the SD image package.
