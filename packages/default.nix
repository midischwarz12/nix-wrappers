# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  inputs',
  inputs,
  self',
  self,
  top,
  lib,
  pkgs,
  ...
}:

let
  inherit (self.lib) ls;

  packages' = ls (self + "/packages");

  genPackage =
    package:
    pkgs.callPackage (self + "/packages/${package}") {
      inherit
        inputs'
        inputs
        self'
        self
        top
        ;
    };
in
lib.genAttrs packages' genPackage
