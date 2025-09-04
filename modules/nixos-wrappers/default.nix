# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  self,
  ...
}:
{
  lib,
  config,
  ...
}:

let
  cfg = config.wrappers;
  inherit (lib.modules) mkIf;
in
{
  imports = [ self.nixosModules.wrapper ];

  config =
    let
      inherit (lib.attrsets)
        attrValues
        filterAttrs
        genAttrs
        mapAttrs
        ;
      inherit (lib.lists) elem;
      inherit (builtins) foldl';
    in
    {
      environment.systemPackages =
        let
          packages = attrValues (
            mapAttrs (_: v: v.finalPackage) (filterAttrs (_: v: v.systemWide) cfg)
          );
        in
        mkIf (packages != []) packages;

      users.users =
        let
          users = foldl' (acc: x: acc ++ x) [ ] (attrValues (mapAttrs (_: v: v.users) cfg));
          userPackages =
            user: attrValues (mapAttrs (_: v: v.finalPackage) (filterAttrs (_: v: elem user v.user) cfg));
        in
        mkIf (users != []) (genAttrs users userPackages);
    };
}
