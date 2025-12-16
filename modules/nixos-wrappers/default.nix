# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  lib,
  config,
  ...
}:

let
  cfg = config.wrappers;
in
{
  imports = [ ../wrappers ];

  config =
    let
      inherit (lib.attrsets)
        attrValues
        filterAttrs
        genAttrs
        mapAttrs
        ;
      inherit (lib.lists)
        unique
        elem
        ;
      inherit (builtins) foldl';
    in
    {
      environment.systemPackages = attrValues (
        mapAttrs (_: v: v.finalPackage) (filterAttrs (_: v: v.systemWide) cfg)
      );

      users.users =
        let
          users = unique (foldl' (acc: x: acc ++ x) [ ] (attrValues (mapAttrs (_: v: v.users) cfg)));
          userPackages = user: {
            packages = attrValues (mapAttrs (_: v: v.finalPackage) (filterAttrs (_: v: elem user v.users) cfg));
          };
        in
        genAttrs users userPackages;
    };
}
