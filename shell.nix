# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  pkgs,
  inputs',
  ...
}:

let
  inherit (pkgs) mkShellNoCC;
in
mkShellNoCC {
  packages = with pkgs; [
    # general
    man-pages
    git
    jq
    ripgrep
    fzf
    fd
    shellcheck

    # nix diffing
    nix-diff
    inputs'.dix.packages.default

    # misc nix
    manix
    nix-tree
    nix-index
    vulnix
    disko
  ];
}
