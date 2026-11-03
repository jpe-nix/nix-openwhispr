{
  pkgs,
  home-manager,
  self,
}:
# Home Manager activation check for the minimal configuration, on every system.
# The option set matches the README quickstart; the manual block is specific to
# this fixture and is not part of the quickstart.
(home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    (import ../modules/home-manager { inherit self; })
    {
      home = {
        username = "ci";
        homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/ci" else "/home/ci";
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
