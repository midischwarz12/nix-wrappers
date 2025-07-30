# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{ lib, flake-parts-lib, ... }:

let
  inherit (lib)
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkTransposedPerSystemModule
    ;
in
mkTransposedPerSystemModule {
  name = "configs";
  option = mkOption {
    type = types.attrs;
    default = { };
    description = "Nvf configs";
  };
  file = ./configs.nix;
}
