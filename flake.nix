# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    flake-parts.url = "github:hercules-ci/flake-parts";

    dix = {
      url = "github:bloxx12/dix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (top: {
      debug = true;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          pkgs,
          lib,
          inputs',
          self',
          ...
        }:
        let
          everything = {
            inherit
              inputs'
              inputs
              self'
              self
              top
              lib
              pkgs
              ;
          };
        in
        {
          packages = import (self + "/packages") everything;
          checks = import (self + "/tests") everything;
          devShells.default = pkgs.callPackage (self + "/shell.nix") { inherit inputs'; };

          formatter = pkgs.writeShellApplication {
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
          };
        };

      flake = {
        lib = import (self + "/lib") {
          inherit (nixpkgs) lib;
        };

        nixosModules = import (self + "/modules") {
          inherit self;
          inherit (nixpkgs) lib;
        };
      };
    });
}
