let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgs' = fetchTarball {
    url = lock.nodes.nixpkgs.locked.url or "https://github.com/NixOS/nixpkgs/archive/${lock.nodes.nixpkgs.locked.rev}.tar.gz";
    sha256 = lock.nodes.nixpkgs.locked.narHash;
  };
in
  {
    nixpkgs ?
      import nixpkgs' {
        config = {};
        overlays = [];
        inherit system;
      },
    system ? builtins.currentSystem,
  }: let
    pkgs = nixpkgs;
    inherit (nixpkgs) lib;

    toProcfile = procGroup:
      lib.concatLines (
        lib.mapAttrsToList (name: cmd: "${name}: ${cmd}") procGroup
      );

    mkRunCommand = procRunner: procfile: let
      inherit (builtins.parseDrvName procRunner.name) name;
      default = "${lib.getExe procRunner} ${procfile}";
    in
      # special cases for officially supported procfile runners
      {
        overmind = ''overmind start -f ${procfile} --root "$PWD" "$@"'';
        honcho = ''honcho start -f ${procfile} --app-root "$PWD" "$@"'';
      }
      .${name}
      or default;
  in {
    mkProcfileRunner = {
      name,
      procGroup,
      procRunner ? pkgs.overmind,
    }:
      pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = [procRunner];
        text = ''
          set -x
          ${mkRunCommand procRunner (
            pkgs.writeText "Procfile" (toProcfile procGroup)
          )}
        '';
      };
  }
