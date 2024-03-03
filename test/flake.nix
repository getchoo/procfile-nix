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

        overmindTestScript = exe: ''
          set -x

          exec ${exe} &
          sleep 5 # avoid race conditions

          if ! overmind status | grep running; then
            echo "Processes failed to launch! Exiting with error"
            overmind kill
            exit 1
          fi

          overmind kill
          echo "Process finished! Exiting as success"
        '';

        redisProc = {
          redis = lib.getExe' pkgs.redis "redis-server";
        };
      in {
        procfiles.overmind-dft.processes = redisProc;
        devShells.overmind-dft = mkTestShell [pkgs.overmind] (overmindTestScript (lib.getExe config.procfiles.overmind-dft.package));

        procfiles.overmind = {
          processes = redisProc;
          procRunner = pkgs.overmind;
        };
        devShells.overmind = mkTestShell [pkgs.overmind] (overmindTestScript (lib.getExe config.procfiles.overmind.package));
      };
    };
}
