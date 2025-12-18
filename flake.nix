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

      forAllSystemsWithPkgs = f: forAllSystems (system: f nixpkgs.legacyPackages.${system});

      # auto-generates outputs based on directories in given path string
      forAllNames =
        pathStr: f: genAttrs (ls (realPath pathStr)) (name: f (realPath "${pathStr}/${name}"));

      forAllSystemsNames = pathStr: f: forAllSystemsWithPkgs (pkgs: forAllNames pathStr (f pkgs));
    in
    {
      packages = forAllSystemsNames "packages" (
        pkgs: path: pkgs.callPackage path { inherit inputs self; }
      );

      nixosModules = forAllNames "modules" (path: {
        imports = [ path ];
      });

      devShells = forAllSystemsWithPkgs (pkgs: {
        default = pkgs.callPackage (realPath "shell.nix") { };
      });

      formatter = forAllSystemsWithPkgs (
        pkgs:
        pkgs.writeShellApplication {
          name = "lint";
          runtimeInputs = with pkgs; [
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
