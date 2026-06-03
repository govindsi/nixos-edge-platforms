# Debian adbd + Android libs (patchelf for NixOS) and USB gadget script.
# https://packages.debian.org/sid/arm64/adbd
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  coreutils,
  util-linux,
  brotli,
  lz4,
  zstd,
  systemd,
  openssl,
}:

let
  version = "34.0.5-12";
  boringsslVersion = "14.0.0+r45-3+b2";

  deb =
    {
      url,
      hash,
    }:
    fetchurl {
      inherit url hash;
    };

  adbdDeb = deb {
    url = "https://deb.debian.org/debian/pool/main/a/android-platform-tools/adbd_${version}+b1_arm64.deb";
    hash = "sha256-ko7m2c6nZVnhBoAPk7w/Ldi+fnKxd4Rxi+YFIUwQYGc=";
  };

  libbaseDeb = deb {
    url = "https://deb.debian.org/debian/pool/main/a/android-platform-tools/android-libbase_${version}+b1_arm64.deb";
    hash = "sha256-2rcP5jLtSXfjRlW2jzBJf6BuzKpWjyzZRzId+u1SwJo=";
  };

  libboringsslDeb = deb {
    url = "https://deb.debian.org/debian/pool/main/a/android-platform-external-boringssl/android-libboringssl_${boringsslVersion}_arm64.deb";
    hash = "sha256-2R6ZYoxJeB9TJ3pboGrj5vex1bG7RmYXYrt/0+5+32Q=";
  };

  libcutilsDeb = deb {
    url = "https://deb.debian.org/debian/pool/main/a/android-platform-tools/android-libcutils_${version}+b1_arm64.deb";
    hash = "sha256-NLk7yvWMX6VLr0eHyQZz5ZZekCARQC8Jo7LCeoHN1rw=";
  };

  liblogDeb = deb {
    url = "https://deb.debian.org/debian/pool/main/a/android-platform-tools/android-liblog_${version}+b1_arm64.deb";
    hash = "sha256-UY0OO+cLo2zX/rK7ub9otPObmEJf3Lpg1U1+QC9S8XQ=";
  };

  # Must match Debian adbd ABI (nixpkgs protobuf_32 is a different build).
  libprotobufDeb = deb {
    url = "https://deb.debian.org/debian/pool/main/p/protobuf/libprotobuf32t64_3.21.12-15+b1_arm64.deb";
    hash = "sha256-GqlUDnb9lrKhUL6msttDzIKckfIS9oZ+vxdGLq7O0Ao=";
  };

  allDebs = [
    adbdDeb
    libbaseDeb
    libboringsslDeb
    libcutilsDeb
    liblogDeb
    libprotobufDeb
  ];
in
stdenv.mkDerivation {
  pname = "qrb2210-adbd";
  version = "${version}+b1";

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    brotli
    lz4
    zstd
    systemd
    openssl
  ];

  unpackPhase = ''
    runHook preUnpack
    mkdir unpacked
    for deb in ${lib.concatStringsSep " " (map (d: "${d}") allDebs)}; do
      dpkg-deb -x "$deb" unpacked
    done
    runHook postUnpack
  '';

  installPhase = ''
        runHook preInstall

        install -d $out/bin $out/lib/qrb2210-adbd
        cp -a unpacked/usr/lib/aarch64-linux-gnu/android/. $out/lib/
        cp -a unpacked/usr/lib/aarch64-linux-gnu/libprotobuf.so.32* $out/lib/
        install -Dm755 unpacked/usr/lib/android-sdk/platform-tools/adbd $out/bin/adbd

        cat > $out/lib/qrb2210-adbd/adbd-usb-gadget <<'GADGET'
    #!/bin/sh
    set -e

    LS=${coreutils}/bin/ls
    HEAD=${coreutils}/bin/head
    SHA256SUM=${coreutils}/bin/sha256sum
    CUT=${coreutils}/bin/cut
    MKDIR=${coreutils}/bin/mkdir
    LN=${coreutils}/bin/ln
    RM=${coreutils}/bin/rm
    RMDIR=${coreutils}/bin/rmdir
    MOUNT=${util-linux}/bin/mount
    UMOUNT=${util-linux}/bin/umount
    MOUNTPOINT=${util-linux}/bin/mountpoint

    UDC="''${ADBD_GADGET_UDC}"
    if [ -n "''${UDC}" ] && [ ! -e "/sys/class/udc/''${UDC}" ]; then
      echo "ERROR: /sys/class/udc/''${UDC} doesn't exist!" >&2
      exit 1
    fi
    if [ -z "''${UDC}" ] && [ -d /sys/class/udc ]; then
      UDC="$("$LS" /sys/class/udc | "$HEAD" -1)"
    fi
    [ -n "''${UDC}" ] || exit 0

    CONFIGFS_DIR=/sys/kernel/config/usb_gadget/g1

    setup() {
      if [ -L "''${CONFIGFS_DIR}/configs/c.1/ffs.adb" ]; then
        "$MOUNTPOINT" -q /dev/usb-ffs/adb || "$MOUNT" -t functionfs adb /dev/usb-ffs/adb
        return 0
      fi

      "$MKDIR" -p "''${CONFIGFS_DIR}/configs/c.1"
      cd "''${CONFIGFS_DIR}"

      "$MKDIR" -p strings/0x409 configs/c.1/strings/0x409

      echo 0x0100 > idProduct
      echo 0x18D1 > idVendor

      echo "Arduino UNO Q" > strings/0x409/manufacturer
      echo "Arduino UNO Q" > strings/0x409/product
      echo "$("$SHA256SUM" < /etc/machine-id | "$CUT" -d' ' -f1)" > strings/0x409/serialnumber

      echo "ADB Configuration" > configs/c.1/strings/0x409/configuration
      echo 120 > configs/c.1/MaxPower

      "$MKDIR" -p functions/ffs.adb
      "$LN" -sf functions/ffs.adb configs/c.1

      "$MKDIR" -p /dev/usb-ffs/adb
      "$MOUNT" -t functionfs adb /dev/usb-ffs/adb
    }

    activate() {
      if [ ! -d "''${CONFIGFS_DIR}" ]; then
        echo "qrb2210-adbd-usb-gadget: ''${CONFIGFS_DIR} missing; run setup first" >&2
        return 1
      fi
      echo "''${UDC}" > "''${CONFIGFS_DIR}/UDC"
    }

    reset() {
      set +e
      if [ -d "''${CONFIGFS_DIR}" ]; then
        echo none > "''${CONFIGFS_DIR}/UDC" 2>/dev/null
      fi
      "$UMOUNT" /dev/usb-ffs/adb 2>/dev/null
      "$RMDIR" /dev/usb-ffs/adb 2>/dev/null
      "$RM" -f "''${CONFIGFS_DIR}/configs/c.1/ffs.adb" 2>/dev/null
      "$RMDIR" "''${CONFIGFS_DIR}/configs/c.1/strings/0x409" 2>/dev/null
      "$RMDIR" "''${CONFIGFS_DIR}/configs/c.1" 2>/dev/null
      "$RMDIR" "''${CONFIGFS_DIR}/functions/ffs.adb" 2>/dev/null
      "$RMDIR" "''${CONFIGFS_DIR}/strings/0x409" 2>/dev/null
      "$RMDIR" "''${CONFIGFS_DIR}" 2>/dev/null
      set -e
    }

    case "$1" in
      setup) setup ;;
      activate) activate ;;
      reset) reset ;;
      *) echo "Usage: $0 [setup|activate|reset]"; exit 1 ;;
    esac
    GADGET

        chmod +x $out/lib/qrb2210-adbd/adbd-usb-gadget

        runHook postInstall
  '';

  meta = {
    description = "Android Debug Bridge daemon for QRB2210 USB gadget (Debian adbd, Nix-patched)";
    homepage = "https://packages.debian.org/sid/adbd";
    license = lib.licenses.asl20;
    platforms = [ "aarch64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
