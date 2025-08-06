{
  stdenv,
  self,
  inputs,
  bash,
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

    chmod +x $out/bin/makeWrapper
    chmod +x $out/bin/wrapProgram
  '';
}
