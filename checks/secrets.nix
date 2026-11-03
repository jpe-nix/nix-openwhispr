{
  pkgs,
  home-manager,
  self,
}:
# Checks that an API key file is referenced only by the start wrapper. The key
# value must never be written to the Nix store, so the generated env file and
# the generated launch service must not contain an OPENAI_API_KEY assignment.
let
  inherit (pkgs) lib;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  hm = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      (import ../modules/home-manager { inherit self; })
      {
        home = {
          username = "ci";
          homeDirectory = if isDarwin then "/Users/ci" else "/home/ci";
          stateVersion = "26.05";
        };
        # Fixture-only: see checks/hm-defaults.nix for why the manual is off.
        manual = {
          manpages.enable = false;
          json.enable = false;
        };
        programs.openwhispr = {
          enable = true;
          apiKeyFiles.openai = "/run/secrets/openai";
        };
      }
    ];
  };
  cfg = hm.config;
  wrapper = lib.findFirst (
    p: lib.hasPrefix "openwhispr-start" (p.name or "")
  ) (throw "openwhispr-start is missing from home.packages") cfg.home.packages;
  envFile = cfg.xdg.configFile."openwhispr/openwhispr.env".source;
  serviceFile =
    if isDarwin then
      pkgs.writeText "com.jpe-nix.nix-openwhispr.plist" (
        lib.generators.toPlist { escape = true; } cfg.launchd.agents.openwhispr.config
      )
    else
      cfg.xdg.configFile."systemd/user/openwhispr.service".source;
in
pkgs.runCommand "openwhispr-secrets-check" { } ''
  if ! grep -q -F '/run/secrets/openai' ${wrapper}/bin/openwhispr-start; then
    echo "the start wrapper does not reference the configured key file" >&2
    exit 1
  fi
  for file in ${envFile} ${serviceFile}; do
    if grep -q -F 'OPENAI_API_KEY=' "$file"; then
      echo "a literal OPENAI_API_KEY assignment appears in $file" >&2
      exit 1
    fi
  done
  test -e ${cfg.home.activationPackage}
  touch $out
''
