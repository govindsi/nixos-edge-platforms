# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
# UCM-i.MX95 EVK host configuration (SD image / on-device rebuild).
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
    deviceTree.name = lib.mkForce "compulab/ucm-imx95.dtb";
    enableAllHardware = lib.mkForce false;
  };

  networking.hostName = "ucm-imx95";
  time.timeZone = "UTC";

  users.users.root.password = "nixos";

  services.openssh.enable = true;
}
