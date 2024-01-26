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
      };
    };
  };
in {
  options = {
    perSystem = mkPerSystemOption ({system, ...}: {
      options.procfiles = mkOption {
        type = types.attrsOf (types.submoduleWith {
          modules = [procfileSubmodule];
          specialArgs = {inherit system;};
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
    });
  };
}
