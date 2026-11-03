{
  pkgs,
  home-manager,
  self,
}:
# Darwin Home Manager activation check for the minimal module configuration.
(home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    (import ../modules/home-manager { inherit self; })
    {
      home = {
        username = "ci";
        homeDirectory = "/Users/ci";
        stateVersion = "26.05";
      };
      programs.openwhispr.enable = true;
      # Home Manager's default manpages build an options.json with nixpkgs'
      # options-doc helper, which emits a builtins.derivation context warning on
      # this pin. The activation check does not read the docs, so they are off
      # here only. The README quickstart keeps the defaults.
      manual = {
        manpages.enable = false;
        json.enable = false;
      };
    }
  ];
}).activationPackage
