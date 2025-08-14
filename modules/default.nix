# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

args@{
  self,
  lib,
  ...
}:

let
  inherit (self.lib) ls;

  modules = ls (self + "/modules");

  genModule = module: import (self + "/modules/${module}") args;
in
lib.genAttrs modules genModule
