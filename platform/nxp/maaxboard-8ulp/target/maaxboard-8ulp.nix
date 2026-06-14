# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# Avnet MaaXBoard 8ULP host configuration (SD image / on-device rebuild).
{ config, lib, ... }:

{
  system.stateVersion = "25.05";

  boot = {
    # Baked into VFAT uEnv.txt via system.build.toplevel/kernel-params.
    consoleLogLevel = 7;

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    initrd.systemd.tpm2.enable = false;
  };

  hardware = {
    deviceTree.name = lib.mkForce "freescale/maaxboard-8ulp.dtb";
    enableAllHardware = lib.mkForce false;
  };

  networking.hostName = "maaxboard-8ulp";
  time.timeZone = "UTC";

  users.users.root.password = "nixos";

  services.openssh.enable = true;
}
