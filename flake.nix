{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [ "aarch64-darwin" ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        gen-tap = pkgs.writeShellApplication {
          name = "gen-tap";
          runtimeInputs = [ pkgs.jq ];
          text = builtins.readFile ./gen-tap.sh;
        };
        default = gen-tap;
      });
    };
}
