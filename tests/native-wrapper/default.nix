# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{ pkgs, self, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  wrapperPkg = self.packages.${system}.default;
in
pkgs.runCommand "native-wrapper-test" {
  buildInputs = [ wrapperPkg pkgs.coreutils ];
} ''
  set -euo pipefail

  export PATH=${wrapperPkg}/bin:$PATH

  mkdir -p $out/bin

  makeWrapperNative ${pkgs.coreutils}/bin/echo $out/bin/echo-wrapped \
    --add-flag "hello" \
    --append-flag "world"

  result=$($out/bin/echo-wrapped)

  if [ "$result" != "hello world" ]; then
    echo "unexpected output: '$result'" >&2
    exit 1
  fi

  touch $out/passed
''
