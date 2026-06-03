# USB ADB gadget (adbd) for host `adb shell` — matches Armbian arduino-uno-q on Debian.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.qrb2210.adb;
  adbdUsbGadget = "${pkgs.qrb2210-adbd}/lib/qrb2210-adbd/adbd-usb-gadget";
in
{
  options.hardware.qrb2210.adb = {
    enable = lib.mkEnableOption "USB ADB gadget (adbd) for shell access from a host PC";

    manufacturer = lib.mkOption {
      type = lib.types.str;
      default = "Arduino UNO Q";
      description = "USB gadget manufacturer string.";
    };

    product = lib.mkOption {
      type = lib.types.str;
      default = "Arduino UNO Q";
      description = "USB gadget product string.";
    };

    udc = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        USB Device Controller name under `/sys/class/udc/`. When null, the first UDC is used.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [
      "libcomposite"
    ];

    environment.systemPackages = [
      pkgs.qrb2210-adbd
    ];

    systemd.services.qrb2210-adbd = {
      description = "Android Debug Bridge (ADB) over USB";
      documentation = [
        "https://packages.debian.org/sid/adbd"
      ];
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "sys-kernel-config.mount"
      ];
      wants = [ "network-online.target" ];

      path = [
        pkgs.coreutils
        pkgs.util-linux
      ];

      serviceConfig = {
        # Match Debian adbd.service: bind UDC only after adbd notifies (FunctionFS ready).
        Type = "notify";
        NotifyAccess = "main";
        Environment = lib.optional (cfg.udc != null) "ADBD_GADGET_UDC=${cfg.udc}";
        ExecStartPre = "${adbdUsbGadget} setup";
        ExecStart = "${pkgs.qrb2210-adbd}/bin/adbd";
        ExecStartPost = "${adbdUsbGadget} activate";
        ExecStopPost = "-${adbdUsbGadget} reset";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
