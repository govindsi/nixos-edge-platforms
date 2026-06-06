# SPDX-FileCopyrightText: 2026 Govind Singh
# SPDX-License-Identifier: GPL-2.0-only
{ ... }:
{
  imports = [ ../../imx9/sd-image.nix ];
  _module.args.target = "imx93";
}
