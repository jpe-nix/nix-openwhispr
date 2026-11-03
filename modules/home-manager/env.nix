# Non-secret environment: typed options plus the freeform `settings` attrs.
# The same set is exported in the session, rendered to an env file that the
# start wrapper reads, and passed to the launchd agent as EnvironmentVariables.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.openwhispr;
  toEnvString = value: if builtins.isBool value then lib.boolToString value else toString value;
  keyValue = pkgs.formats.keyValue { };
  typed = lib.filterAttrs (_: value: value != null) {
    OPENWHISPR_CHANNEL = "production";
    LOCAL_TRANSCRIPTION_PROVIDER = cfg.transcription.provider;
    LOCAL_WHISPER_MODEL = cfg.transcription.whisperModel;
    PARAKEET_MODEL = cfg.transcription.parakeetModel;
    UI_LANGUAGE = cfg.uiLanguage;
    LANGUAGE = cfg.language;
    OPENWHISPR_LOG_LEVEL = cfg.logLevel;
    VITE_AUTH_URL = cfg.endpoints.authUrl;
    VITE_OPENWHISPR_API_URL = cfg.endpoints.apiUrl;
  };
  environment = (lib.mapAttrs (_: toEnvString) cfg.settings) // typed;
in
{
  options.programs.openwhispr.environment = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = environment;
    readOnly = true;
    internal = true;
    description = "Resolved non-secret environment. Read by the service and wrapper modules.";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = environment;
    xdg.configFile."openwhispr/openwhispr.env".source = keyValue.generate "openwhispr.env" environment;
  };
}
