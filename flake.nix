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

    source-2-30-2 = {
      url = "github:prisma/prisma-engines/2.30.2";
      flake = false;
    };

    source-4-3-1 = {
      url = "github:prisma/prisma-engines/4.3.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, naersk, nix-utils, fenix, ... }@inputs:
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
          source = inputs.source-2-30-2;
          version = "2.30.2";
          cargoSha256 = "sha256-X5qE/jg8vzsnLob7i0nifNzAvvr9cIBh5gl6wW9PIkw=";
        };
        prisma-engines-4-3-1 = import ./nix/prisma-engines.nix {
          source = inputs.source-4-3-1;
          version = "4.3.1";
          cargoSha256 = "sha256-todo/jg8vzsnLob7i0nifNzAvvr9cIBh5gl6wW9PIkw=";
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

          defaultPackage = packages.prisma-engines-4-3-1;

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
