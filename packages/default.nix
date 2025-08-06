# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

everything@{
  self,
  lib,
  pkgs,
  ...
}:

let
  inherit (self.lib) ls;

  packages' = ls (self + "/packages");

  genPackage =
    package:
    pkgs.callPackage (self + "/packages/${package}") everything;
in
lib.genAttrs packages' genPackage
