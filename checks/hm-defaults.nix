{ pkgs, home-manager }:
# Darwin Home Manager activation check for the minimal v1 module configuration.
(home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    ../modules/home-manager.nix
    {
      home = {
        username = "ci";
        homeDirectory = "/Users/ci";
        stateVersion = "26.05";
      };
      programs.openwhispr.enable = true;
    }
  ];
}).activationPackage
