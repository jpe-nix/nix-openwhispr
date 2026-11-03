{
  description = "Home Manager configuration using nix-openwhispr";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openwhispr = {
      url = "github:jpe-nix/nix-openwhispr";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix-openwhispr,
      ...
    }:
    {
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        # Replace with the Mac's system if it is Intel (x86_64-darwin).
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [
          nix-openwhispr.homeManagerModules.default
          {
            home = {
              username = "your-username";
              homeDirectory = "/Users/your-username";
              stateVersion = "26.05";
            };
            programs.openwhispr.enable = true;
          }
        ];
      };
    };
}
