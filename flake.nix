{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-utils = {
      url = "git+https://git.sr.ht/~ilkecan/nix-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, naersk, nix-utils, fenix }:
    let
      inherit (builtins) attrNames attrValues;
      inherit (nixpkgs.lib) getAttrs;
      inherit (flake-utils.lib) eachSystem;
      inherit (nix-utils.lib) createOverlays;

      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      commonArgs = {
        platforms = supportedSystems;
      };
      derivations = {
        prisma-engines-2-30-2 = import ./nix/prisma-engines.nix {
          version = "2.30.2";
          hash = "1890yffp876nh892i80cyn6ls4sd9d92n09pfbqypvfy7c9akpyz";
          cargoSha256 = "sha256-X5qE/jg8vzsnLob7i0nifNzAvvr9cIBh5gl6wW9PIkw=";
        };
      };
    in
    {
      overlays = createOverlays derivations {
        inherit nix-utils;
      };
      overlay = self.overlays.prisma-engines-2-30-2;
    } // eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = attrValues self.overlays ++ [
            fenix.overlay
          ];
        };

        packageNames = attrNames derivations;
      in
        rec {
          packages = getAttrs packageNames pkgs;

          defaultPackage = packages.prisma-engines-2-30-2;

          devShell =
            let
              packageList = attrValues packages;
            in
              pkgs.mkShell {
                packages = packageList ++ [
                  defaultPackage.rustToolchain.defaultToolchain
                ];
                inputsFrom = packageList;
          };
        }
    );
}
