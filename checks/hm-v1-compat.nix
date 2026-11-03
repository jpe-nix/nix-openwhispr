{
  pkgs,
  home-manager,
  self,
}:
# Evaluates the v1 option names. The programs.openwhispr block below must stay
# identical to the v1 snippet in docs/MIGRATION.md. The check fails unless the
# evaluation emits exactly the four rename warnings, and then builds the
# activation package.
let
  inherit (pkgs) lib;
  hm = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      (import ../modules/home-manager { inherit self; })
      {
        home = {
          username = "ci";
          homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/ci" else "/home/ci";
          stateVersion = "26.05";
        };
        programs.openwhispr = {
          enable = true;
          autoStart = false;
          modelBootstrap = true;
          localTranscriptionProvider = "whisper";
          whisperModel = "base";
        };
        # Fixture-only: see checks/hm-defaults.nix for why the manual is off.
        manual = {
          manpages.enable = false;
          json.enable = false;
        };
      }
    ];
  };
  expectedRenames = [
    "autoStart"
    "modelBootstrap"
    "localTranscriptionProvider"
    "whisperModel"
  ];
  warnings = hm.config.warnings;
  renamedWarning = name: lib.any (w: lib.hasInfix "programs.openwhispr.${name}'" w) warnings;
in
assert lib.assertMsg (
  builtins.length warnings == builtins.length expectedRenames
  && builtins.all renamedWarning expectedRenames
) "hm-v1-compat: expected exactly the four v1 rename warnings, got: ${builtins.toJSON warnings}";
hm.config.home.activationPackage
