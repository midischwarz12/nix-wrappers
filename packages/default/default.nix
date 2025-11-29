# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  stdenv,
  self,
  inputs,
  bash,
  python3,
  ...
}:

let
  inherit (inputs) nixpkgs;
in
stdenv.mkDerivation {
  name = "wrapProgram";
  src = self + "/src";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/libexec

    cp ${nixpkgs}/pkgs/build-support/setup-hooks/die.sh $out/libexec/die.sh

    substitute ${nixpkgs}/pkgs/build-support/setup-hooks/make-wrapper.sh $out/libexec/make-wrapper.sh \
      --subst-var-by shell ${bash}/bin/bash

    substitute $src/makeWrapper.sh $out/bin/makeWrapper \
      --subst-var-by out $out \
      --subst-var-by bash ${bash}/bin/bash
    substitute $src/wrapProgram.sh $out/bin/wrapProgram \
      --subst-var-by out $out \
      --subst-var-by bash ${bash}/bin/bash
    substitute $src/nix-wrappers.sh $out/bin/nix-wrappers \
      --subst-var-by out $out \
      --subst-var-by bash ${bash}/bin/bash
    substitute $src/makeWrapperNative.sh $out/bin/makeWrapperNative \
      --subst-var-by out $out \
      --subst-var-by bash ${bash}/bin/bash \
      --subst-var-by python ${python3}/bin/python3 \
      --subst-var-by runner $out/bin/wrapper-runner

    ${stdenv.cc}/bin/cc -O2 -std=c11 $src/wrapper_runner.c -o $out/bin/wrapper-runner

    chmod +x $out/bin/makeWrapper
    chmod +x $out/bin/wrapProgram
    chmod +x $out/bin/nix-wrappers
    chmod +x $out/bin/makeWrapperNative
  '';
}
