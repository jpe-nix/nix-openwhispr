# Typed options under programs.openwhispr. Every option names its environment
# variable or launchd/systemd effect in its description.
{ self }:
{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkOption
    types
    ;
  flakePackage = name: self.packages.${pkgs.stdenv.hostPlatform.system}.${name};
  # Each apiKeyFiles field maps to <NAME>_API_KEY, e.g. openai -> OPENAI_API_KEY.
  apiKeyNames = [
    "openai"
    "anthropic"
    "gemini"
    "groq"
    "mistral"
    "tinfoil"
  ];
in
{
  options.programs.openwhispr = {
    enable = mkEnableOption "OpenWhispr";

    package = mkOption {
      type = types.package;
      default = flakePackage "openwhispr";
      defaultText = literalExpression "nix-openwhispr.packages.\${system}.openwhispr";
      example = literalExpression "pkgs.openwhispr";
      description = "OpenWhispr application package. Defaults to this flake's package for the host system.";
    };

    # v1 assigned a package to this option. A package is coerced through a throw
    # that names the replacement, instead of the submodule's unknown-attribute
    # error that a derivation would otherwise produce.
    models = mkOption {
      type =
        types.coercedTo types.package
          (
            _:
            throw "programs.openwhispr.models is now a submodule: set programs.openwhispr.models.package instead of assigning a package (see docs/MIGRATION.md)."
          )
          (
            types.submodule {
              options = {
                package = mkOption {
                  type = types.package;
                  default = flakePackage "models";
                  defaultText = literalExpression "nix-openwhispr.packages.\${system}.models";
                  example = literalExpression "pkgs.openwhispr-models";
                  description = "Hash-pinned local models linked into the upstream cache layout.";
                };

                bootstrap = mkOption {
                  type = types.bool;
                  default = true;
                  example = false;
                  description = "Link the pinned Whisper, diarization, and semantic-search models into ~/.cache/openwhispr.";
                };
              };
            }
          );
      default = { };
      example = {
        bootstrap = false;
      };
      description = "Local model bootstrap: the pinned models package and whether to link it.";
    };

    autostart.enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = "Start OpenWhispr at login: a launchd agent on Darwin, a systemd user service on Linux.";
    };

    transcription = {
      provider = mkOption {
        type = types.enum [
          "whisper"
          "parakeet"
        ];
        default = "whisper";
        example = "parakeet";
        description = "Local engine pre-warmed at startup. Sets LOCAL_TRANSCRIPTION_PROVIDER.";
      };

      whisperModel = mkOption {
        type = types.str;
        default = "base";
        example = "small";
        description = "Pinned Whisper model pre-warmed for local transcription. Sets LOCAL_WHISPER_MODEL.";
      };

      parakeetModel = mkOption {
        type = types.str;
        default = "parakeet-tdt-0.6b-v3";
        example = "parakeet-tdt-0.6b-v3";
        description = "Parakeet model pre-warmed when transcription.provider is parakeet. Sets PARAKEET_MODEL.";
      };
    };

    language = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "en";
      description = "Transcription language code. Sets LANGUAGE; null leaves automatic detection.";
    };

    uiLanguage = mkOption {
      type = types.enum [
        "en"
        "es"
        "fr"
        "de"
        "pt"
        "it"
      ];
      default = "en";
      example = "de";
      description = "Interface language. Sets UI_LANGUAGE.";
    };

    logLevel = mkOption {
      type = types.nullOr (
        types.enum [
          "error"
          "warn"
          "info"
          "debug"
        ]
      );
      default = null;
      example = "debug";
      description = "Log level. Sets OPENWHISPR_LOG_LEVEL; null keeps the application default.";
    };

    endpoints = {
      authUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://auth.example.com";
        description = "Self-hosted auth server URL. Sets VITE_AUTH_URL; null keeps the upstream default.";
      };

      apiUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://api.example.com";
        description = "OpenWhispr API URL. Sets VITE_OPENWHISPR_API_URL; null keeps the upstream default.";
      };
    };

    apiKeyFiles = mkOption {
      type = types.submodule {
        options = lib.genAttrs apiKeyNames (
          name:
          mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "/run/secrets/${name}";
            description = "Absolute path to a file holding the ${lib.toUpper name}_API_KEY value. The file is read when OpenWhispr starts; its contents never enter the Nix store.";
          }
        );
      };
      default = { };
      example = {
        openai = "/run/secrets/openai";
      };
      description = "Paths to files holding provider API keys. Only the paths are stored in the Nix store.";
    };

    settings = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.str
          types.int
          types.bool
        ]
      );
      default = { };
      example = {
        WHISPER_MODEL = "whisper-1";
      };
      description = "Freeform non-secret environment variables for settings without a typed option. Typed options win when both set the same name. Values are stored in the Nix store; never put secrets here.";
    };
  };
}
