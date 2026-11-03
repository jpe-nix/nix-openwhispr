# Options

Upstream OpenWhispr reads its settings from environment variables. This page
maps each variable in upstream's `.env.example` at the v1.11.0 tag, plus the
local-transcription variables and `OPENWHISPR_CHANNEL` that the application
reads from its code, to the typed option that sets it.

Status values:

- `typed`: set by the typed option named in the entry.
- `secret path`: `apiKeyFiles` holds a path; the file is read at start.
- `fixed`: set by the module; not configurable.
- Not typed: set through the freeform `settings` option.

## Upstream variables

- `VITE_AUTH_URL` ([`.env.example` L3][env-3]): typed as `endpoints.authUrl`.
- `VITE_OPENWHISPR_API_URL` ([L6][env-6]): typed as `endpoints.apiUrl`.
- `OPENAI_API_KEY` ([L10][env-10]): secret path, `apiKeyFiles.openai`.
- `WHISPER_MODEL` ([L14][env-14]): not typed. It names an OpenAI cloud model;
  set it with `settings.WHISPER_MODEL`. Local Whisper is
  `LOCAL_WHISPER_MODEL`.
- `LANGUAGE` ([L18][env-18]): typed as `language`.
- `UI_LANGUAGE` ([L21][env-21]): typed as `uiLanguage`.
- `ANTHROPIC_API_KEY` ([L25][env-25]): secret path,
  `apiKeyFiles.anthropic`.
- `GEMINI_API_KEY` ([L29][env-29]): secret path, `apiKeyFiles.gemini`.
- `GROQ_API_KEY` ([L33][env-33]): secret path, `apiKeyFiles.groq`.
- `TINFOIL_API_KEY` ([L37][env-37]): secret path, `apiKeyFiles.tinfoil`.
- `MISTRAL_API_KEY` ([L41][env-41]): secret path, `apiKeyFiles.mistral`.
- `OPENWHISPR_LOG_LEVEL` ([L44][env-44]): typed as `logLevel`.
- `LOCAL_TRANSCRIPTION_PROVIDER` ([main.js L1461][main-1461]): typed as
  `transcription.provider`.
- `LOCAL_WHISPER_MODEL` ([main.js L1462][main-1462]): typed as
  `transcription.whisperModel`.
- `PARAKEET_MODEL` ([main.js L1470][main-1470]): typed as
  `transcription.parakeetModel`.
- `OPENWHISPR_CHANNEL` ([main.js L72][main-72]): fixed to `production`.

## Module-only options

- `enable`: install the application and its start wrapper.
- `package`: the application package. Defaults to this flake's package for the
  host system.
- `models.package`: the pinned local models package. Defaults to this flake's
  package.
- `models.bootstrap`: link the pinned Whisper, diarization, and semantic-search
  models into `~/.cache/openwhispr`. Default `true`.
- `autostart.enable`: start at login, with a launch agent on macOS or a systemd
  user service on Linux. Default `true`.
- `apiKeyFiles.<provider>`: absolute path to a key file for `openai`,
  `anthropic`, `gemini`, `groq`, `mistral`, or `tinfoil`. Default `null`.
- `settings`: freeform, non-secret environment variables. Typed options win when
  both set the same name. Values are stored in the Nix store, so never put a
  secret here.

## Environment and precedence

The module resolves the non-secret values from the typed options and `settings`.
It renders them to `openwhispr.env` under the XDG config directory, exports them
in the session, and passes them to the launch agent on macOS. The start wrapper
reads that file, exports each key file's contents as `<PROVIDER>_API_KEY`, and
then starts the application. Key contents are read at start and never enter the
Nix store.

The application also reads `.env` from its data directory, `<userData>/.env`.
[`main.js` L97-L102][main-dotenv] loads it without override, and
[`environment.js` L78-L81][env-js] loads it again with override enabled. Keys
saved in the application's Settings are written to that file. A value in it
replaces the module's value for the same name, so a key saved in Settings takes
precedence over `apiKeyFiles`.

The module does not link or write that file. An existing one is left in place.

[env-3]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L3
[env-6]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L6
[env-10]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L10
[env-14]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L14
[env-18]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L18
[env-21]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L21
[env-25]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L25
[env-29]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L29
[env-33]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L33
[env-37]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L37
[env-41]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L41
[env-44]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/.env.example#L44
[main-72]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/main.js#L72
[main-1461]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/main.js#L1461
[main-1462]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/main.js#L1462
[main-1470]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/main.js#L1470
[main-dotenv]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/main.js#L97-L102
[env-js]: https://github.com/OpenWhispr/openwhispr/blob/v1.11.0/src/helpers/environment.js#L78-L81
