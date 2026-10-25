# Evaluates the generated taps with brew-nix's mkTaps, so CI only commits data
# brew-nix can read. Run from the repository root: `nix flake check ./tests`.
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    brew-nix = {
      url = "github:glassesneo/brew-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-taps-api = {
      url = "path:..";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      brew-nix,
      brew-taps-api,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      systems = [ "aarch64-darwin" ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      checks = forAllSystems (pkgs: {
        eval-taps =
          let
            brewTaps = brew-nix.lib.mkTaps {
              inherit pkgs;
              source = "${brew-taps-api}/taps";
            };
            drvPaths = lib.collect lib.isString (lib.mapAttrs (_: lib.mapAttrs (_: lib.mapAttrs (_: cask: cask.drvPath))) brewTaps);
          in
          pkgs.writeText "eval-taps" (builtins.unsafeDiscardStringContext (lib.concatLines drvPaths));
      });
    };
}
