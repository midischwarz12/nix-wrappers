<div align="center">

# Nix-Wrappers

### ***Wrap... Inject... Done!***

</div>

<br/>
<br/>

Nix-Wrappers makes
[wrappers](https://nixos.org/manual/nixpkgs/stable/#fun-makeWrapper) for nix
packages that creates a modified environment (see: [#Features](#features) for
specifics).

This can be used as an optimal way to modify the package's environment without:
- mutating the global environment of the user(s) **or**
- mutating the file system outside the nix-store (/nix/store).

This means there's never:
- dangling files left from old configurations **or**
- any special linker required to properly symlink files from the nix-store to
  paths outside the nix-store.

Under nominal conditions, this makes Nix-Wrappers ideal for managing dotfiles
and other configurations in most situations. Situations where Nix-Wrappers is
not ideal for managing such include packages that:
- do not have an command line flag or environment variable to the configuration path **and**
- do not respect XDG variables from the XDG Base Directory Specification.

In rare situations like these, we recommend using:
- [hjem](https://github.com/feel-co/hjem) with [their special
    linker](https://github.com/feel-co/smfh) **or**
- using [systemd-tmpfilesd](https://search.nixos.org/options?query=systemd.tmpfiles)

## Features

On a per package basis, Nix-Wrappers can:
- Change the directory of the package's environment.
- Set commands to run immediately after the program's execution as a part of the
    package environment.
- Prepend and/or append arguments to be ran as a part of the package
    environment.
- Set environment variables of the package's environment.
- Unset environment variables of the package's environment.
- Add values as prefixes and/or suffixes to the delimited list environment
    variables of the package's environment.

## Getting Started

### CLI Tool

<details>
  <summary>Flake (Current recommendation):</summary>

  In your flake.nix, add the following to inputs, outputs' arguments, and your
  NixOS configurations' modules.

  ```nix
  {
    inputs = {
      # Add `wrappers` to inputs
      wrappers = {
        type = "git";
        url = "https://codeberg.org/midischwarz12/nix-wrappers";
      };
    };
  }
  ```

  *Remember to `nix flake update wrappers`*

  And then consume it whatever way you see fit whether devShell,
  nixosConfiguration, etc.
</details>

<details>
  <summary>Ad hoc with `nix shell` or `nix run`:</summary>

  With `nix run`:

  ```console
  $ nix run 'git+https://codeberg.org/midischwarz12/nix-wrappers' -- <args>
  ...
  ```
  
  With `nix shell`:

  ```console
  $ nix shell 'git+https://codeberg.org/midischwarz12/nix-wrappers'
  $ wrapProgram <exec> -- <args>
  ...
  ```

  Or run with makeWrapper.
</details>

### NixOS Module

<details>
  <summary>Flake (Current recommendation):</summary>

  In your flake.nix, add the following to inputs, outputs' arguments, and your
  NixOS configurations' modules.

  ```nix
  {
    inputs = {
      # Add `wrappers` to inputs
      wrappers = {
        type = "git";
        url = "https://codeberg.org/midischwarz12/nix-wrappers";
      };
    };

    outputs =
      {
        # Add `wrappers` to outputs' arguments
        wrappers,
        ...
      }: {
        nixosConfigurations.foo = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # Add `wrappers` to list of modules
            wrappers.nixosModules.default
          ];
        };
      }
  }
  ```

  *Remember to `nix flake update wrappers`*
</details>

<details>
  <summary>niv</summary>

*Planned and coming soonTM*
</details>

<details>
  <summary>npins</summary>

*Planned and coming soonTM*
</details>

<details>
  <summary>nix-channel</summary>

*Planned and coming soonTM*
</details>

<details>
  <summary>fetchTarball</summary>

*Planned and coming soonTM*
</details>

## Usage

### CLI Tool

#### `makeWrapper`

```console
$ makeWrapper <exec> <out-path> <args>
```

Where args are:

- --argv0        NAME    : set the name of the executed process to NAME
-                          (if unset or empty, defaults to EXECUTABLE)
- --inherit-argv0        : the executable inherits argv0 from the wrapper.
-                          (use instead of --argv0 '$0')
- --resolve-argv0        : if argv0 doesn't include a / character, resolve it against PATH
- --set          VAR VAL : add VAR with value VAL to the executable's environment
- --set-default  VAR VAL : like --set, but only adds VAR if not already set in
-                          the environment
- --unset        VAR     : remove VAR from the environment
- --chdir        DIR     : change working directory (use instead of --run "cd DIR")
- --run          COMMAND : run command before the executable
- --add-flag     ARG     : prepend the single argument ARG to the invocation of the executable
-                          (that is, *before* any arguments passed on the command line)
- --append-flag  ARG     : append the single argument ARG to the invocation of the executable
-                          (that is, *after* any arguments passed on the command line)
- --add-flags    ARGS    : prepend ARGS verbatim to the Bash-interpreted invocation of the executable
- --append-flags ARGS    : append ARGS verbatim to the Bash-interpreted invocation of the executable
- 
- --prefix          ENV SEP VAL   : suffix/prefix ENV with VAL, separated by SEP
- --suffix
- --prefix-each     ENV SEP VALS  : like --prefix, but VALS is a list
- --suffix-each     ENV SEP VALS  : like --suffix, but VALS is a list
- --prefix-contents ENV SEP FILES : like --suffix-each, but contents of FILES
-                                   are read first and used as VALS
- --suffix-contents

#### `wrapProgram`

```console
$ wrapProgram <exec> <args>
```

Where args are:

- --set          VAR VAL : add VAR with value VAL to the executable's environment
- --set-default  VAR VAL : like --set, but only adds VAR if not already set in
-                          the environment
- --unset        VAR     : remove VAR from the environment
- --chdir        DIR     : change working directory (use instead of --run "cd DIR")
- --run          COMMAND : run command before the executable
- --add-flag     ARG     : prepend the single argument ARG to the invocation of the executable
-                          (that is, *before* any arguments passed on the command line)
- --append-flag  ARG     : append the single argument ARG to the invocation of the executable
-                          (that is, *after* any arguments passed on the command line)
- --add-flags    ARGS    : prepend ARGS verbatim to the Bash-interpreted invocation of the executable
- --append-flags ARGS    : append ARGS verbatim to the Bash-interpreted invocation of the executable
- 
- --prefix          ENV SEP VAL   : suffix/prefix ENV with VAL, separated by SEP
- --suffix
- --prefix-each     ENV SEP VALS  : like --prefix, but VALS is a list
- --suffix-each     ENV SEP VALS  : like --suffix, but VALS is a list
- --prefix-contents ENV SEP FILES : like --suffix-each, but contents of FILES
-                                   are read first and used as VALS
- --suffix-contents

### NixOS Module

In your NixOS configuration, add the following:

```nix
{
  wrappers = {
    # Creates a wrapper around `foo` with the environment variable
    # `FOO_CONFIG` set to a nix-store path.
    "foo" = {
      basePackage = pkgs.foo;
      environment."FOO_CONFIG".value = self + "/path/to/foo/config.toml";
    };

    # Creates a wrapper around `bar` with the command line flag `--config`
    # pointing to a path in the nix-store.
    "bar" = {
      basePackage = pkgs.bar;
      args.suffix = [ "--config ${self + "/path/to/bar/config.json"}" ];
    };
  };
}
```

Then the wrappers can be consumed by `config.wrappers.foo.finalPackage` and
`config.wrappers.bar.finalPackage` respectively.

For example, to use in a `.package` option assuming `programs.foo` exists:

```nix
{
  programs.foo = {
    enable = true;
    package = config.wrappers.foo.finalPackage;
  };
}
```

Or to add a wrapper to a package list:

```nix
  environment.systemPackages = [
    config.wrappers.bar.finalPackage
  ];
}
```

Full documentation will be generated for all the available options soonTM.

## Roadmap

- Thorough documentation with examples
- More installation methods
- Nix function for return wrappers
