# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  pkgs,
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
    dix

    # misc nix
    manix
    nix-tree
    nix-index
    vulnix
    disko
  ];
}
