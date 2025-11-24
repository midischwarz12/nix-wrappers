# SPDX-License-Identifier: AGPL-3.0-or-later
# Copyright (c) 2025 midischwarz12

{
  pkgs,
  lib,
  ...
}:

{
  options =
    let
      inherit (lib.attrsets) attrsToList;
      inherit (lib.options) mkOption mkEnableOption;
      inherit (lib.strings) optionalString;
      inherit (lib.types)
        attrs
        attrsOf
        bool
        listOf
        nullOr
        package
        path
        str
        submodule
        ;
      inherit (builtins) foldl';
      inherit (pkgs) symlinkJoin;

      environmentType = submodule {
        options = {
          value = mkOption {
            type = str;
            default = "";
            description = "Set the value of the environment variable.";
          };

          default = mkOption {
            type = str;
            default = "";
            description = "Set the value of the environment variable if not already set.";
          };

          unset = mkOption {
            type = bool;
            default = false;
            description = "Whether to unset the environment variable.";
          };

          delimiter = mkOption {
            type = str;
            default = ":";
            description = "Delimiter used for environment variables which are lists.";
          };

          prefix = mkOption {
            type = listOf str;
            default = [ ];
            description = "Prepend value to the environment variable list.";
          };

          suffix = mkOption {
            type = listOf str;
            default = [ ];
            description = "Append value to the environment variable list.";
          };
        };
      };

      executableType = submodule (
        { name, ... }:
        {
          options = {
            name = mkOption {
              type = str;
              default = name;
            };

            directory = mkOption {
              type = nullOr path;
              default = null;
              description = "Change the directory of the package's environment.";
            };

            preRun = mkOption {
              type = listOf str;
              default = [ ];
              description = "Commands to run before the execution of the program";
            };

            args = {
              prefix = mkOption {
                type = listOf str;
                default = [ ];
                description = "Arguments to prepend to the beginning of the wrapped program's arguments.";
              };

              suffix = mkOption {
                type = listOf str;
                default = [ ];
                description = "Arguments to append to the end of the wrapped program's arguments.";
              };
            };

            environment = mkOption {
              type = attrsOf environmentType;
              default = { };
              description = "Manage the wrapper's environment variables.";
            };
          };
        }
      );

      wrapperType = submodule (
        { config, name, ... }:
        {
          options = {
            basePackage = mkOption {
              type = package;
              default = pkgs.${name};
            };

            finalPackage = mkOption {
              type = package;
              description = "Output derivation containing the wrapper of the package.";
              readOnly = true;
              default = symlinkJoin {
                inherit name;
                inherit (config) passthru;

                paths = [ config.basePackage ] ++ config.extraPackages;
                nativeBuildInputs = [ pkgs.makeWrapper ];

                postBuild =
                  let
                    wrappers = foldl' (acc: exe:
                      let
                        envPairs = attrsToList exe.value.environment;

                        listToSepString = delimiter: xs: foldl' (a: x: "${a}${delimiter}${x}") "" xs;
                        envFlag =
                          n: v:
                          if (v.value != "") then
                            "--set ${n} ${v.value}"
                          else if (v.default != "") then
                            "--set-default ${n} ${v.default}"
                          else if v.unset then
                            "--unset ${n}"
                          else if (v.prefix != [ ]) then
                            "--prefix ${n} ${v.delimiter} ${listToSepString v.delimiter v.prefix}"
                          else if (v.suffix != [ ]) then
                            "--suffix ${n} ${v.delimiter} ${listToSepString v.delimiter v.suffix}"
                          else
                            "";
                      in
                      acc + ''
                        mv \
                          $out/bin/${exe.name} \
                          $out/bin/.${exe.name}-wrapper-base
                        makeWrapper \
                          $out/bin/.${exe.name}-wrapper-base \
                          $out/bin/${exe.value.name} \
                          --argv0 ${exe.value.name} \
                          ${optionalString (exe.value.directory != null) "--chdir ${exe.value.directory}"} \
                          ${foldl' (a: x: "${a} --run ${x}") "" exe.value.preRun} \
                          ${foldl' (a: x: "${a} --add-flag ${x}") "" exe.value.args.prefix} \
                          ${foldl' (a: x: "${a} --append-flag ${x}") "" exe.value.args.suffix} \
                          ${foldl' (a: x: "${a} ${envFlag x.name x.value}") "" envPairs}
                      '') "" (attrsToList config.executables);

                    substitutions = ''
                      find $out -type l | while read link; do
                        target="$(readlink -f "$link")"
                        if [ -f "$target" ] && file -b --mime-encoding "$target" | grep -q "^us-ascii\|^utf-8\|^utf-16be\|^utf-16le\|^utf-32be\|^utf-32le"; then
                          case "$target" in
                            ${config.basePackage}/*)
                              rm "$link"
                              substitute "$target" "$link" \
                                --replace-quiet "${config.basePackage}" "$out"
                          esac
                        fi
                      done
                    '';
                  in
                  wrappers + substitutions;
              };
            };

            # No-op when not on NixOS
            users = mkOption {
              type = listOf str;
              default = [ ];
              example = [
                "johnsmith"
                "root"
              ];
            };

            # No-op when not on NixOS
            systemWide = mkEnableOption "system-wide installation";

            extraPackages = mkOption {
              type = listOf package;
              default = [ ];
              description = "Additional packages needed in the wrapper's environment $PATH.";
            };

            passthru = mkOption {
              type = attrs;
              default = { };
            };

            executables = mkOption {
              type = attrsOf executableType;
              default = {};
            };
          };
        }
      );
    in
    {
      wrappers = mkOption {
        type = attrsOf wrapperType;
        default = {};
      };
    };
}
