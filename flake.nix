{
  description = "Procfile generation in your Nix shells!";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
  in {
    lib = forAllSystems (pkgs:
      import ./. {
        nixpkgs = pkgs;
        inherit (pkgs) system;
      });

    flakeModule = import ./module.nix self;

    formatter = forAllSystems (pkgs: pkgs.alejandra);
  };
}
