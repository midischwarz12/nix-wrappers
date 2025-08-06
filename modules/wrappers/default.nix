{ pkgs, lib, config, ... }:

let
  cfg = config.wrappers;
  inherit (lib.modules) mkIf;
in
{
  options = let
    inherit (lib.attrsets) attrsToList;
    inherit (lib.options) mkOption mkEnableOption;
    inherit (lib.strings) optionalString;
    inherit (lib.types) attrsOf bool listOf nullOr package path str submodule;
    inherit (builtins) foldl';

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
          default = [];
          description = "Prepend value to the environment variable list.";
        };

        suffix = mkOption {
          type = listOf str;
          default = [];
          description = "Append value to the environment variable list.";
        };
      };
    };

    wrapperType = submodule ({ config, ... }: {
      options = {
        basePackage = mkOption {
          type = package;
          description = "Package being wrapped";
        };

        name = mkOption {
          type = str;
          description = "Package name";
          default = "${config.basePackage.name}-wrapped";
        };

        executable = mkOption {
          type = str;
          description = "File to be executed";

          # Assuming for most packages, the executable is the name of the package
          default = config.basePackage.pname;
        };

        finalPackage = mkOption {
          type = package;
          description = "Output derivation containing the wrapper of the package.";
          readOnly = true;
          default =
            pkgs.symlinkJoin {
              inherit (config) name;
              paths = [ config.basePackage ] ++ config.extraPackages;
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild =
                let
                  envPairs = attrsToList config.environment;

                  listToSepString = delimiter: xs: foldl' (a: x: "${a}${delimiter}${x}") "" xs;
                  envFlag = n: v:
                    if (v.value != "") then
                      "--set ${n} ${v.value}"
                    else if (v.default != "") then
                      "--set-default ${n} ${v.default}"
                    else if v.unset then
                      "--unset ${n}"
                    else if (v.prefix != []) then
                      "--prefix ${n} ${v.delimiter} ${listToSepString v.delimiter v.prefix}"
                    else if (v.suffix != []) then
                      "--suffix ${n} ${v.delimiter} ${listToSepString v.delimiter v.suffix}"
                    else
                      ""
                    ;
                in
                  ''
                    wrapProgram $out/bin/${config.executable} \
                      ${optionalString (config.directory != null) "--chdir ${config.directory}"} \
                      ${foldl' (a: x: "${a} --run ${x}") "" config.run} \
                      ${foldl' (a: x: "${a} --add-flag ${x}") "" config.args.prefix} \
                      ${foldl' (a: x: "${a} --append-flag ${x}") "" config.args.suffix} \
                      ${foldl' (a: x: "${a} ${envFlag x.name x.value}") "" envPairs} \
                  '';
            };
        };

        users = mkOption {
          type = listOf str;
          default = [];
          example = [ "johnsmith" "root" ];
        };

        systemWide = mkEnableOption "system-wide installation";

        directory = mkOption {
          type = nullOr path;
          default = null;
          description = "Change the directory of the package's environment.";
        };

        extraPackages = mkOption {
          type = listOf package;
          default = [];
          description = "Additional packages needed in the wrapper's environment $PATH.";
        };

        run = mkOption {
          type = listOf str;
          default = [];
          description = "Commands to run before the execution of the program";
        };

        args = {
          prefix = mkOption {
            type = listOf str;
            default = [];
            description = "Arguments to prepend to the beginning of the wrapped program's arguments.";
          };

          suffix = mkOption {
            type = listOf str;
            default = [];
            description = "Arguments to append to the end of the wrapped program's arguments.";
          };
        };

        environment = mkOption {
          type = attrsOf environmentType;
          default = {};
          description = "Manage the wrapper's environment variables.";
        };
      };
    });
  in {
    wrappers = mkOption {
      type = attrsOf wrapperType;
      default = {};
      example = {};
      description = "Wrappers to be managed by Hjem.";
    };
  };

  config = let
    inherit (lib.attrsets) attrValues filterAttrs genAttrs mapAttrs;
    inherit (lib.lists) elem;
    inherit (builtins) foldl';
  in
  {
    environment.systemPackages = attrValues (mapAttrs (_: v: v.finalPackage) (filterAttrs (_: v: v.systemWide) cfg));

    users.users = let
      users = foldl' (acc: x: acc ++ x) [] (attrValues (mapAttrs (_: v: v.users) cfg));
      userPackages = user: attrValues (mapAttrs (_: v: v.finalPackage) (filterAttrs (_: v: elem user v.user) cfg));
    in
    mkIf (users != []) (genAttrs users userPackages);
  };
}
