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

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          wrapperPackage = self.packages.${system}.default;
          moduleWrapper =
            (nixpkgs.lib.evalModules {
              specialArgs = { inherit pkgs; };
              modules = [
                (realPath "modules/default")
                {
                  wrappers.hello = {
                    basePackage = pkgs.hello;
                    executables.hello.environment.NIX_WRAPPERS_SMOKE.value = "1";
                  };
                }
              ];
            }).config.wrappers.hello.finalPackage;
        in
        {
          inherit (self.packages.${system}) default;

          shellcheck =
            pkgs.runCommand "nix-wrappers-shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; }
              ''
                find ${realPath "src"} -name '*.sh' -print0 \
                  | xargs -0 shellcheck -s bash -e SC1008,SC1091,SC2239
                touch $out
              '';

          cli-wrapper-smoke =
            pkgs.runCommand "nix-wrappers-cli-wrapper-smoke"
              {
                nativeBuildInputs = [
                  wrapperPackage
                  pkgs.gnugrep
                ];
              }
              ''
                mkdir -p bin
                cp ${pkgs.coreutils}/bin/printf bin/printf
                wrapProgram "$PWD/bin/printf" --add-flag 'wrapped\n'
                "$PWD/bin/printf" | grep -qx wrapped
                touch $out
              '';

          module-wrapper-smoke =
            pkgs.runCommand "nix-wrappers-module-wrapper-smoke"
              {
                nativeBuildInputs = [
                  moduleWrapper
                  pkgs.gnugrep
                ];
              }
              ''
                hello | grep -qx 'Hello, world!'
                touch $out
              '';
        }
      );

      nixosModules = forAllNames "modules" (path: {
        imports = [ path ];
      });

      darwinModules.default.imports = [ (realPath "modules/system-wrappers") ];

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
