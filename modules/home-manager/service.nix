# Packages the start wrapper, the login service, and the API-key handling.
#
# The wrapper reads each configured key file when it runs and exports the value
# into the process environment; key contents are never written to the store.
# The systemd user service always starts the wrapper, which execs the
# application binary. The launchd agent starts the application binary directly
# and gets its environment from EnvironmentVariables; it uses the wrapper only
# when apiKeyFiles names a key file, because launchd cannot read a file into an
# environment variable.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.openwhispr;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  envFile = "${config.xdg.configHome}/openwhispr/openwhispr.env";
  appExecutable =
    if isDarwin then
      "${cfg.package}/Applications/OpenWhispr.app/Contents/MacOS/OpenWhispr"
    else
      "${cfg.package}/bin/openwhispr";
  # Upstream's desktop entry passes --no-sandbox on Linux; the wrapper does too.
  sandboxArgs = lib.optionalString isLinux "--no-sandbox ";
  configuredKeys = lib.filterAttrs (_: path: path != null) cfg.apiKeyFiles;
  apiKeyExports = lib.concatStrings (
    lib.mapAttrsToList (
      name: path:
      let
        var = "${lib.toUpper name}_API_KEY";
      in
      ''
        if [ ! -r ${lib.escapeShellArg path} ]; then
          echo "openwhispr: the ${name} API key file is not readable" >&2
          exit 1
        fi
        ${var}="$(cat -- ${lib.escapeShellArg path})"
        export ${var}
      ''
    ) configuredKeys
  );
  startScript = pkgs.writeShellApplication {
    name = "openwhispr-start";
    text = ''
      if [ -r ${lib.escapeShellArg envFile} ]; then
        while IFS='=' read -r key value || [ -n "$key" ]; do
          export "$key=$value"
        done < ${lib.escapeShellArg envFile}
      fi
      ${apiKeyExports}
      exec ${lib.escapeShellArg appExecutable} ${sandboxArgs}"$@"
    '';
  };
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [
          cfg.package
          startScript
        ];

        assertions = lib.mapAttrsToList (name: path: {
          assertion = lib.hasPrefix "/" path;
          message = "programs.openwhispr.apiKeyFiles.${name} must be an absolute path to the key file, not a relative path or a Nix path literal.";
        }) configuredKeys;
      }

      (lib.mkIf isDarwin {
        # A v1 agent used the com.dryvist label. Unload it so the renamed agent
        # does not run alongside it; a missing or unloaded agent is not an error.
        home.activation.bootoutLegacyOpenWhispr = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          legacyPlist="$HOME/Library/LaunchAgents/com.dryvist.nix-openwhispr.plist"
          if [ -e "$legacyPlist" ]; then
            run /bin/launchctl bootout "gui/$(/usr/bin/id -u)" "$legacyPlist" || true
          fi
        '';
      })

      (lib.mkIf (isDarwin && cfg.autostart.enable) {
        launchd.agents.openwhispr = {
          enable = true;
          config = {
            Label = "com.jpe-nix.nix-openwhispr";
            ProgramArguments = [
              (if configuredKeys == { } then appExecutable else lib.getExe startScript)
            ];
            EnvironmentVariables = cfg.environment;
            RunAtLoad = true;
            KeepAlive = {
              SuccessfulExit = false;
            };
            ProcessType = "Interactive";
            ThrottleInterval = 10;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/OpenWhispr/stdout.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/OpenWhispr/stderr.log";
          };
        };
      })

      (lib.mkIf (isLinux && cfg.autostart.enable) {
        systemd.user.services.openwhispr = {
          Unit = {
            Description = "OpenWhispr voice dictation";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = lib.getExe startScript;
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      })
    ]
  );
}
