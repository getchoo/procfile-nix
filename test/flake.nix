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
      }: {
        procfiles.daemons.processes = {
          redis = lib.getExe' pkgs.redis "redis-server";
        };

        devShells.default = pkgs.mkShellNoCC {
          packages = [
            (pkgs.writeShellScriptBin "run-ci" ''
              set -x

              exec ${lib.getExe config.procfiles.daemons.package} &
              sleep 5 # avoid race conditions

              if ! overmind status | grep running; then
                echo "Processes failed to launch! Exiting with error"
                overmind kill
                exit 1
              fi

              overmind kill
              echo "Process finished! Exiting as success"
            '')
          ];
        };
      };
    };
}
