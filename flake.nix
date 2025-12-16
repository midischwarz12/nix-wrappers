# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    systems.url = "github:nix-values/default";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      inherit (nixpkgs.lib) genAttrs;

      ls = path: builtins.attrNames (builtins.readDir path);
      realPath = pathStr: self + "/${pathStr}";

      forAllSystems = genAttrs (import systems);

      genArgs = system: {
        inherit self inputs;
        inherit (nixpkgs) lib;
        pkgs = nixpkgs.legacyPackages.${system};
      };

      forAllSystemsWithArgs = f: forAllSystems (system: f (genArgs system));

      # auto-generates outputs based on directories in given path string
      genOutput =
        pathStr: f:
        (forAllSystemsWithArgs (
          args: genAttrs (ls (realPath pathStr)) (dir: f (realPath "${pathStr}/${dir}") args)
        ));
    in
    {
      packages = genOutput "packages" (path: args: args.pkgs.callPackage path args);

      nixosModules = genAttrs
        (ls (realPath "modules"))
        (module: import (realPath "modules/${module}"));

      devShells = forAllSystemsWithArgs (args: {
        default = args.pkgs.callPackage (realPath "shell.nix") { };
      });

      formatter = forAllSystemsWithArgs (
        args:
        args.pkgs.writeShellApplication {
          name = "lint";
          runtimeInputs = with args.pkgs; [
            nixfmt-rfc-style
            deadnix
            statix
            shellcheck
            fd
          ];
          text = ''
            fd '.*\.nix' . -x statix fix -- {} \; -x deadnix -e -- {} \; -x nixfmt {} \;
            fd '.*\.sh' . -x shellcheck {} \;
          '';
        }
      );
    };
}
