# procfile-nix

A library + [flake-parts](https://flake.parts/) module that helps you manage procfiles and background jobs with [overmind](https://github.com/DarthSim/overmind) (or any other Procfile runner)!

## Usage

Regardless of if you use the library or flakeModule, you will be putting a package into your development shells.
Following this, the name you gave the Procfile will be avalible as a command while will setup all of your processes.

Example:

```shell
$ nix develop
$ myprocfile
```

You can also send the command to run in the background like so: `myprocfile &`

## Usage (library)

First, put this in your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    procfile-nix = {
      url = "github:getchoo/procfile-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, procfile-nix, ... }: let
    systems = [ "x86_64-linux" "aarch64-linux" ];

    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems ({
      lib,
      pkgs,
      system,
      ...
    }: let
      procfile = procfile-nix.lib.${system}.mkProcfileRunner {
        name = "daemons";

        procGroup = {
          redis = lib.getExe' pkgs.redis "redis-server";
        };

        # OPTIONAL: switch the Procfile runner if desired.
        procRunner = pkgs.honcho;
      };
    in {
      default = pkgs.mkShell {
        packages = [ procfile ];
      };
    });
  };
}
```

Then run `nix develop`, `daemons &`, and you're good to go!

## Usage (flakeModule)

```nix
{

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    procfile-nix = {
      url = "github:getchoo/procfile-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      imports = [ inputs.procfile-nix.flakeModule ];

      perSystem = {
        config,
        lib,
        pkgs,
        ...
      }: {
        procfiles.daemons = {
          processes = {
            redis = lib.getExe' pkgs.redis "redis-server";
          };
          
          # OPTIONAL: switch the Procfile runner if desired.
          procRunner = pkgs.honcho;
        };

        devShells.default = pkgs.mkShell {
          packages = [ config.procfiles.daemons.package ];
        };
      };
    };
}
```

Similar to the last example, `nix develop` and `daemons &` may be run to start your Procfile
