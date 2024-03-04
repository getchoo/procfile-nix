{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    call-flake.url = "github:divnix/call-flake";
  };

  outputs = inputs:
    inputs.parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [(inputs.call-flake ../.).flakeModule];

      debug = true;

      perSystem = {
        config,
        lib,
        pkgs,
        ...
      }: let
        mkTestShell = runtimeInputs: text:
          pkgs.mkShellNoCC {
            packages = [
              (pkgs.writeShellApplication {
                name = "run-ci";

                inherit runtimeInputs text;
              })
            ];
          };

        testScript = exe: check: kill:  ''
          set -x

          ${exe}
          sleep 5 # avoid race conditions

          if ${check}; then
            echo "Processes failed to launch! Exiting with error"
            ${kill}
            exit 1
          fi

          ${kill}
          echo "Process finished! Exiting as success"
        '';

        dummyProc = {
          redis = lib.getExe' pkgs.redis "redis-server";
        };
      in {
        # overmind as default
        procfiles.overmind-dft.processes = dummyProc;
        devShells.overmind-dft = mkTestShell [pkgs.overmind] (
          testScript
            "exec ${(lib.getExe config.procfiles.overmind-dft.package)} &"
            "! overmind status | grep running"
            "overmind kill"
          );

        # explicit overmind
        procfiles.overmind = {
          processes = dummyProc;
          procRunner = pkgs.overmind;
        };
        devShells.overmind = mkTestShell [pkgs.overmind] (
          testScript
            "exec ${(lib.getExe config.procfiles.overmind.package)} &"
            "! overmind status | grep running"
            "overmind kill"
          );

        # honcho
        procfiles.honcho = {
          processes = dummyProc;
          procRunner = pkgs.honcho;
        };
        devShells.honcho = mkTestShell [pkgs.honcho] (
          testScript
            ''
            exec ${(lib.getExe config.procfiles.honcho.package)} & \
            PROC_PID=$!
            ''
            "! ps -p \"$PROC_PID\" > /dev/null"
            "kill -2 $PROC_PID; pkill -f \"redis\""
        );
      };
    };
}
