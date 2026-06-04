# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# i.MX93 EVK host configuration (SD image / on-device rebuild).
{ config, lib, ... }:

{
  system.stateVersion = "25.05";

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    initrd.systemd.tpm2.enable = false;
  };

  hardware = {
    deviceTree.name = lib.mkForce "freescale/imx93-11x11-evk.dtb";
    enableAllHardware = lib.mkForce false;
  };

  networking.hostName = "imx93-evk";
  time.timeZone = "UTC";

  users.users.root.password = "nixos";

  services.openssh.enable = true;
}
