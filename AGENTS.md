# nix-openwhispr

This repository owns reproducible Nix packaging and macOS lifecycle
integration for the upstream OpenWhispr application.

## Boundaries

- Keep local processing usable without an account or hosted-service credential.
- Do not add local word, duration, speaker-count, retention, or subscription
  limits.
- Keep cloud, team, billing, and hosted API behavior explicitly service-backed.
- Infrastructure belongs in the owning OpenTofu repository; guest configuration
  belongs in the owning Ansible repository.
- Launchd jobs start a distinctly named executable (the application
  binary), never `/bin/sh`, `bash`, `env`, or another interpreter; privacy
  (TCC) access belongs to that named binary only. The one exception is
  `apiKeyFiles`: launchd cannot read a file into an environment variable, so
  the agent then runs `openwhispr-start`, which execs the application binary.
- Never commit credentials, private host details, local-machine paths, or
  private project identifiers.

## Validation

```sh
nix flake check --all-systems --no-build
nix fmt -- --check
./scripts/check-publication.sh
```

Every change uses a feature branch and an isolated worktree. Release jobs are
trusted-ref only and must not expose long-lived credentials to pull requests.
