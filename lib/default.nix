# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

args@{ lib, ... }:

let
  # helper used internally
  mkEval = {
    pkgs,
    wrappers,
    extraModules ? [ ],
    extraSpecialArgs ? { },
  }:
    lib.evalModules {
      modules = [
        ../modules/wrappers/default.nix
        { config.wrappers = wrappers; }
      ] ++ extraModules;

      specialArgs = {
        inherit pkgs;
        lib = pkgs.lib;
      } // extraSpecialArgs;
    };
in
rec {
  ls =
    path:
    let
      paths = builtins.readDir path;
    in
    builtins.filter (name: paths.${name} == "directory") (builtins.attrNames paths);

  # Evaluate the wrappers module without setting up a full module system.
  # Returns the full evaluated config/options; most callers will want
  # `result.config.wrappers`.
  evalWrappers = mkEval;

  # Convenience: return only the final derivations (attrset of packages).
  mkWrappers = {
    pkgs,
    wrappers,
    extraModules ? [ ],
    extraSpecialArgs ? { },
  }:
    let
      evaluated = mkEval {
        inherit pkgs wrappers extraModules extraSpecialArgs;
      };
    in
    lib.mapAttrs (_: v: v.finalPackage) evaluated.config.wrappers;

  # Convenience: build a single wrapper derivation.
  mkWrapper = {
    pkgs,
    name,
    wrapper,
    extraModules ? [ ],
    extraSpecialArgs ? { },
  }:
    let
      wrappers = { "${name}" = wrapper; };
    in
    mkWrappers {
      inherit pkgs wrappers extraModules extraSpecialArgs;
    }.${name};
}
