# CompuLab platforms

| Board | Path | nixos-hardware module |
| ----- | ------ | --------------------- |
| UCM-i.MX95 EVK | [ucm-imx95](./ucm-imx95/) | `ucm-imx95` |

SD image layout matches other i.MX9x boards (shared [imx9 helpers](../nxp/imx9/)).

## Build

```bash
nix build .#packages.x86_64-linux.ucm-imx95-sd-image
```

Flash `flash.bin` at a 32 KiB offset:

```bash
sudo dd if=./result/flash.bin of=/dev/sdX bs=1k seek=32 conv=fsync
```
