# First-boot eMMC rootfs grow for Qualcomm GPT layouts (Arduino UNO Q / QRB2210).
# Port of https://github.com/armbian/build/blob/main/packages/bsp/arduino/armbian-resize-filesystem-qcom
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.qrb2210.resizeRootfs;

  resizeScript = pkgs.writeShellScript "qrb2210-resize-rootfs" ''
    set -euo pipefail

    FLAG=${cfg.flagFile}
    DISK=${cfg.disk}
    ROOTPART=${toString cfg.rootPartition}
    USERPART=${toString cfg.userdataPartition}

    # Only run once.
    if [ -f "$FLAG" ]; then
      exit 0
    fi

    # Qualcomm eMMC layout only — skip SD/MBR images (e.g. mmcblk0p2).
    root_src=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
    if [ "$root_src" != "''${DISK}p''${ROOTPART}" ]; then
      echo "qrb2210-resize-rootfs: root is $root_src, not ''${DISK}p''${ROOTPART}; skipping"
      exit 0
    fi

    if [ ! -b "''${DISK}" ]; then
      echo "qrb2210-resize-rootfs: $DISK not found; skipping"
      exit 0
    fi

    SGDISK=${pkgs.gptfdisk}/bin/sgdisk
    PARTPROBE=${pkgs.util-linux}/bin/partprobe
    RESIZE2FS=${pkgs.e2fsprogs}/bin/resize2fs

    # Remove empty userdata partition if present.
    "$SGDISK" -d "$USERPART" "$DISK" 2>/dev/null || true

    # Move backup GPT to end of disk.
    "$SGDISK" -e "$DISK"

    STARTLBA=$("$SGDISK" -i "$ROOTPART" "$DISK" | grep "First sector" | awk '{print $3}')

    # Recreate rootfs using all remaining space.
    "$SGDISK" -d "$ROOTPART" \
      -n "''${ROOTPART}:''${STARTLBA}:0" \
      -t "''${ROOTPART}:8305" \
      -c "''${ROOTPART}:rootfs" \
      "$DISK"

    "$PARTPROBE" "$DISK"
    "$RESIZE2FS" "''${DISK}p''${ROOTPART}"

    mkdir -p "$(dirname "$FLAG")"
    touch "$FLAG"
  '';
in
{
  options.hardware.qrb2210.resizeRootfs = {
    enable = lib.mkEnableOption "first-boot grow of eMMC root partition 68 on Qualcomm boards";

    disk = lib.mkOption {
      type = lib.types.str;
      default = "/dev/mmcblk0";
      description = "Block device for onboard eMMC.";
    };

    rootPartition = lib.mkOption {
      type = lib.types.int;
      default = 68;
      description = "GPT partition number for the ext4 root filesystem.";
    };

    userdataPartition = lib.mkOption {
      type = lib.types.int;
      default = 69;
      description = "GPT partition number for empty userdata (removed before grow).";
    };

    flagFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/.rootfs-expanded";
      description = "Marker file written after a successful resize.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.qrb2210-resize-rootfs = {
      description = "Expand QRB2210 eMMC rootfs to fill available space";
      after = [ "local-fs.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = resizeScript;
      };
    };
  };
}
