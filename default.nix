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
  in {
    mkProcfileRunner = {
      name,
      procGroup,
    }:
      pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = [pkgs.overmind];
        text = ''
          set -x
          overmind start -f ${pkgs.writeText name (toProcfile procGroup)} --root "$PWD" "$@"
        '';
      };
  }
