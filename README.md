# nix-openwhispr

[![CI](https://github.com/jpe-nix/nix-openwhispr/actions/workflows/ci.yml/badge.svg)](https://github.com/jpe-nix/nix-openwhispr/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Reproducible Nix packaging and lifecycle integration for
[OpenWhispr](https://github.com/OpenWhispr/openwhispr), a local-first voice
dictation, meeting transcription, speaker identification, and notes application.

This repository packages the upstream application; it does not fork or
reimplement the application. The default path is local processing.

## Installation

Run the application without configuring anything:

```sh
nix run "github:jpe-nix/nix-openwhispr?ref=v2"
```

Home Manager, minimal configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openwhispr = {
      url = "github:jpe-nix/nix-openwhispr?ref=v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nix-openwhispr, ... }: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        nix-openwhispr.homeManagerModules.default
        {
          home = {
            username = "me";
            homeDirectory = "/Users/me";
            stateVersion = "26.05";
          };
          programs.openwhispr.enable = true;
        }
      ];
    };
  };
}
```

The module installs the application and a start wrapper. With
`autostart.enable` set, which is the default, it also installs a launch agent on
macOS or a systemd user service on Linux. Set `autostart.enable = false` to
start the application by hand.

On macOS the launch agent starts the application binary directly and passes the
non-secret environment through launchd, so privacy prompts name OpenWhispr.
When `apiKeyFiles` names a key file, the agent runs the start wrapper instead.
The wrapper reads the key files and then execs the application binary. The
systemd user service on Linux always runs the wrapper. The application's own
menu bar controls remain available independently of the login service.

The upstream application owns its menu-bar item and runtime model lifecycle.
This integration pre-warms the selected local engine and links hash-pinned
baseline models into the cache paths the upstream application actually reads.
The upstream application does not expose a supported declarative setting for
its first-run processing mode: select **Local** for dictation, meetings, and
audio import in its Settings once. This package deliberately does not mutate
its internal browser storage to simulate that selection. On macOS the package
preserves and verifies the upstream Developer ID signature and notarization; it
does not replace them with an ad-hoc signature. `models.json` records the helper
and model provenance used by the pinned release.

`models.bootstrap` (default `true`) links the pinned Whisper, diarization, and
semantic-search models. Parakeet and local LLM models remain owned by the
upstream model manager or the consuming `nix-ai`/`nix-darwin` configuration;
this package does not duplicate or scan the shared Hugging Face/MLX cache.

## Usage

Start the application with the `nix run` command above, or let the login
service start it. The menu-bar or tray item opens the application's panel,
where dictation, meetings, and notes are controlled. Its Settings hold the
processing mode described under Installation.

## What is available locally

The upstream application provides local speech-to-text, meeting capture,
speaker diarization, voice fingerprints, notes, semantic search, local
reasoning, audio import, and a menu-bar/tray application. Local processing is
not subject to the hosted service's word quota.

- **Dictation and translation**: local models. Uses the local machine's
  resources.
- **Meeting transcription**: local models. Requires microphone and system-audio
  permissions on macOS.
- **Speaker labels and voice fingerprints**: local ONNX models. Best supported
  on Apple Silicon.
- **Notes and semantic search**: local SQLite/vector data. Search quality
  depends on downloaded models.
- **AI agent**: local model or explicit provider. Provider credentials are
  user-selected.
- **API and MCP**: not exposed locally by this upstream desktop release. The
  hosted API/MCP service is account-backed and rate-limited.
- **Team spaces, hosted sharing, billing**: hosted service. Requires the
  upstream service/account.
- **Optional remote inference**: explicit LAN endpoint. Must be configured and
  authenticated separately.

No local word, duration, speaker-count, retention, or subscription limit is
introduced by this package. Intel Macs are supported for the application where
upstream dependencies permit; upstream currently documents that local speaker
identification and voice fingerprints are unavailable on Intel because of its
ONNX Runtime dependency.

## Platforms

- `aarch64-darwin`: DMG; Home Manager and nix-darwin modules.
- `x86_64-darwin`: DMG; Home Manager and nix-darwin modules.
- `x86_64-linux`: AppImage; Home Manager (systemd user service) and NixOS
  modules.

Every module option and check output is listed in
[docs/options.md](docs/options.md).

## Options

Options are typed under `programs.openwhispr`. The main ones are:

- `enable`: install the application and its start wrapper.
- `autostart.enable`: start at login, default `true`.
- `models.bootstrap`: link the pinned local models, default `true`.
- `transcription.provider`: `whisper` (default) or `parakeet`.
- `transcription.whisperModel`: Whisper model name, default `base`.
- `transcription.parakeetModel`: Parakeet model name.
- `apiKeyFiles.<provider>`: paths to API key files, read at start.
- `settings`: freeform, non-secret environment variables.

Each upstream environment variable and its typed option is listed in
[docs/options.md](docs/options.md).

## Secrets

`apiKeyFiles` takes the path of a file for each provider. The application reads
the file when it starts; only the path enters the Nix store.

```nix
programs.openwhispr = {
  enable = true;
  apiKeyFiles.openai = "/run/secrets/openai";
};
```

Use a quoted absolute path. The module rejects relative paths, and the file
contents are never copied into the store. A key saved in the application's own
Settings is written to its data directory and takes precedence over
`apiKeyFiles`; see [docs/options.md](docs/options.md).

## Migrating from v1

The v1 option names still work and print a warning naming their replacement.
The steps and the full mapping are in [docs/MIGRATION.md](docs/MIGRATION.md).

## Plan-boundary policy

Every locally implementable desktop capability is available without a package
quota: local transcription, local meeting processing, diarization, speaker
fingerprints, local notes/search, and locally configured agents. The upstream
Business and Enterprise plans also include managed cloud transcription, cloud
sync/mobile, hosted API/MCP, organization administration, SSO/SCIM, audit
logs, and retention controls. Those are proprietary account services, so this
repository neither claims to provide them locally nor attempts to bypass their
plans or rate limits.

## First-run permissions

macOS will request microphone, input monitoring, accessibility, and system
audio permissions as features are used. Grant only the permissions required
for the workflows you enable. Verify the installed bundle and launch state with:

```sh
nix run .#verify-local -- "$HOME/Applications/OpenWhispr.app"
```

## Optional homelab routing

Remote inference, vector storage, backups, and MCP/API gateways are optional
extensions. They belong in the owning infrastructure and application
repositories, not in this public client package. A future deployment should
provision infrastructure through OpenTofu, configure services through Ansible,
obtain credentials through OpenBao, and expose only authenticated LAN routes.

The local client must remain fully useful when every remote service is offline.
No recording, transcript, or voice profile is uploaded unless the user
explicitly selects a remote route.

## Development and release

```sh
nix develop
nix flake check --all-systems --no-build
nix fmt -- --fail-on-change
./scripts/check-publication.sh
```

Pull requests run on GitHub-hosted Linux runners, including a KVM-enabled Linux
runner for the NixOS VM check, and on Apple Silicon runners. The release
workflow reserves the Apple Silicon artifact for a disposable Tart macOS VM on
the Mac Studio, using one-job JIT runner registration; this isolated runner
must be provisioned and accepted before a release can use its label. The Intel
compatibility artifact uses a GitHub-hosted Intel macOS runner. The self-hosted
label is restricted to this repository and trusted release refs. Any private
signing material is restricted to reviewed release environments. See
`docs/mac-studio-runner.md` and `docs/acceptance.md`.

## API

The flake exposes `packages.<system>` (`default`, `openwhispr`, `models`),
`apps.<system>.default`, `apps.aarch64-darwin.verify-local` and
`apps.x86_64-darwin.verify-local`, `overlays.default`,
`homeManagerModules.default` (alias `homeModules.default`),
`nixosModules.default`, `darwinModules.default`, and `templates.default`.

## Contributing

Open a pull request from a feature branch. Run the checks under
Development and release before requesting review.

## License

The Nix integration in this repository is MIT licensed. The packaged
application and its bundled dependencies retain their upstream licenses; see
`docs/provenance.md` and the upstream release metadata.

---

Documentation: <https://docs.jacobpevans.com>
