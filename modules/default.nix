# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  self,
  lib,
  ...
}:

let
  inherit (self.lib) ls;

  modules = ls (self + "/modules");

  genModule = module: { imports = [ (self + "/modules/${module}") ]; };
in
lib.genAttrs modules genModule
