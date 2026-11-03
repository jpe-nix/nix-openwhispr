{
  description = "Reproducible macOS Nix integration for OpenWhispr";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nix-devenv = {
      url = "github:dryvist/nix-devenv?ref=v0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        dryvist-github.follows = "dryvist-github";
      };
    };
    dryvist-github = {
      url = "github:dryvist/.github?ref=v1";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      flake-parts,
      nix-devenv,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      imports = [ nix-devenv.flakeModules.nix ];

      flake = {
        overlays.default = final: _prev: {
          openwhispr = final.callPackage ./pkgs/openwhispr { };
          openwhispr-models = final.callPackage ./pkgs/openwhispr-models { };
        };
        homeManagerModules.default = import ./modules/home-manager.nix;
        homeModules.default = self.homeManagerModules.default;
        templates.default = {
          path = ./templates/default;
          description = "Home Manager configuration using nix-openwhispr";
        };
      };

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        let
          isDarwin = nixpkgs.lib.elem system [
            "aarch64-darwin"
            "x86_64-darwin"
          ];
          launcher = pkgs.writeShellApplication {
            name = "openwhispr-launch";
            text = ''
              exec /usr/bin/open -na "${config.packages.default}/Applications/OpenWhispr.app" --args "$@"
            '';
          };
          verifier = pkgs.writeShellApplication {
            name = "openwhispr-verify-local";
            runtimeInputs = [
              pkgs.bash
              pkgs.coreutils
            ];
            text = builtins.readFile ./scripts/verify-local.sh;
          };
        in
        {
          packages = nixpkgs.lib.optionalAttrs isDarwin (
            let
              openwhispr = pkgs.callPackage ./pkgs/openwhispr { };
              models = pkgs.callPackage ./pkgs/openwhispr-models { };
            in
            {
              default = openwhispr;
              inherit models openwhispr;
            }
          );

          apps = nixpkgs.lib.optionalAttrs isDarwin {
            default = {
              type = "app";
              program = "${launcher}/bin/openwhispr-launch";
            };
            verify-local = {
              type = "app";
              program = "${verifier}/bin/openwhispr-verify-local";
            };
          };

          checks = {
            publication =
              pkgs.runCommand "openwhispr-publication-check"
                {
                  nativeBuildInputs = [ pkgs.ripgrep ];
                }
                ''
                  bash ${self}/scripts/check-publication.sh
                  touch $out
                '';
          }
          // nixpkgs.lib.optionalAttrs isDarwin {
            module = import ./checks/hm-defaults.nix { inherit pkgs home-manager; };
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [ config.pre-commit.devShell ];
            packages = with pkgs; [
              nixfmt
              statix
              deadnix
              shellcheck
              ripgrep
            ];
          };
        };
    };
}
