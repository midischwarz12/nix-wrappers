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

  tests = ls (self + "/tests");

  genTest =
    test:
    pkgs.callPackage (self + "/tests/${test}") {
      inherit
        inputs'
        inputs
        self'
        self
        top
        ;
    };
in
lib.genAttrs tests genTest
