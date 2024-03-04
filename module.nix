self: {
  lib,
  flake-parts-lib,
  ...
}: let
  inherit
    (flake-parts-lib)
    mkPerSystemOption
    ;

  inherit
    (lib)
    literalExpression
    mdDoc
    mkOption
    types
    ;

  procfileSubmodule = {
    config,
    name,
    system,
    pkgs,
    ...
  }: {
    options = {
      processes = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = mdDoc "Attribute set mapping the names of processes to their command";
        example = literalExpression ''
          {
            redis = lib.getExe' pkgs.redis "redis-server";
          }
        '';
      };

      procRunner = mkOption {
        type = types.package;
        description = mdDoc ''
          The Procfile runner to use. Default: overmind. supports: overmind, honcho. If using an unsupported procRunner,
          the Procfile path will be passed as an argument to the procRunner.
        '';
        default = pkgs.overmind;
      };

      package = mkOption {
        type = types.package;
        description = mdDoc "Final package containing runner for Procfile";
        readOnly = true;
      };
    };

    config = {
      package = self.lib.${system}.mkProcfileRunner {
        inherit name;
        procGroup = config.processes;
        procRunner = config.procRunner;
      };
    };
  };
in {
  options = {
    perSystem = mkPerSystemOption ({
      system,
      pkgs,
      ...
    }: {
      options = {
        procRunner = mkOption {
          type = types.package;
          default = pkgs.overmind;
          description = mdDoc "The Procfile runner to use. Default: overmind, supports: overmind, honcho";
          example = literalExpression ''
            daemons = {
              processes.redis = lib.getExe' pkgs.redis "redis-server";
              procRunner = pkgs.honcho;
            };
          '';
        };

        procfiles = mkOption {
          type = types.attrsOf (types.submoduleWith {
            modules = [procfileSubmodule];
            specialArgs = {inherit system pkgs;};
          });

          default = {};
          description = mdDoc "Attribute set containing procfile declarations";
          example = literalExpression ''
            {
              daemons.processes = {
                redis = lib.getExe' pkgs.redis "redis-server";
            	};
            }
          '';
        };
      };
    });
  };
}
