# Migrating from v1 to v2

v2 renames the Home Manager options, adds Linux support and NixOS and
nix-darwin modules, and changes the flake URL to
`github:jpe-nix/nix-openwhispr`.

## Who this is for

Users of `github:dryvist/nix-openwhispr?ref=v1` in a Home Manager
configuration. Users of upstream OpenWhispr's `nix/module.nix` on NixOS are
covered in the last section.

## Breaking changes

- The flake URL is `github:jpe-nix/nix-openwhispr`; v1 used
  `github:dryvist/nix-openwhispr`. Use `?ref=v2`.
- The v1 option names still work and print a warning. Rename them as shown
  below.
- `programs.openwhispr.models` is a submodule. Set `models.package` instead of
  assigning a package to `models`. Assigning a package fails with an error that
  names the replacement.
- The launch agent label changed from `com.dryvist.nix-openwhispr` to
  `com.jpe-nix.nix-openwhispr`. Activation runs `launchctl bootout` on the v1
  agent's plist when that file exists, so the old and new agents do not run
  together. The module does not delete the old plist file.
- The launch agent starts the start wrapper, which execs the application binary.
  v1 started the binary directly.
- The module does not link or write the application's `.env` file in its data
  directory. Keys already there stay where they are. See
  [the environment section](options.md#environment-and-precedence).

## Other changes

- `x86_64-linux` is supported: the application package wraps the Linux AppImage.
- On Linux, `autostart.enable` starts a systemd user service.
- The `nixosModules.default` and `darwinModules.default` outputs are new.

## Option mapping

- `enable`: unchanged.
- `package`: unchanged. Defaults to this flake's package for the host system.
- `models`: now `models.package`, inside a submodule that also has
  `models.bootstrap`.
- `modelBootstrap`: now `models.bootstrap`. Renamed; warns.
- `autoStart`: now `autostart.enable`. Renamed; warns.
- `localTranscriptionProvider`: now `transcription.provider`. Renamed; warns.
- `whisperModel`: now `transcription.whisperModel`. Renamed; warns.
- `parakeetModel`: now `transcription.parakeetModel`. Renamed; warns.

## Before and after

Before, with `github:dryvist/nix-openwhispr?ref=v1`. This is the configuration
that the `hm-v1-compat` check evaluates:

```nix
programs.openwhispr = {
  enable = true;
  autoStart = false;
  modelBootstrap = true;
  localTranscriptionProvider = "whisper";
  whisperModel = "base";
};
```

After, with `github:jpe-nix/nix-openwhispr?ref=v2`:

```nix
programs.openwhispr = {
  enable = true;
  autostart.enable = false;
  models.bootstrap = true;
  transcription = {
    provider = "whisper";
    whisperModel = "base";
  };
};
```

## Steps

1. Change the input URL to `github:jpe-nix/nix-openwhispr?ref=v2`.
2. Run `nix flake update nix-openwhispr`.
3. Rebuild with your usual Home Manager or nix-darwin command.
4. Read the warnings. Each one names the v2 option.
5. Rename each option using the mapping above, then rebuild. The warnings stop
   when no v1 name remains.

## Rollback

Set the input back to `github:dryvist/nix-openwhispr?ref=v1` and rebuild. The
v1 tag is on that repository, and GitHub redirects the former name to the
renamed repository. If the v2 launch agent is still loaded after the rollback,
check it with `launchctl print gui/$(id -u)/com.jpe-nix.nix-openwhispr` and stop
it with `launchctl bootout gui/$(id -u)/com.jpe-nix.nix-openwhispr`.

## Upstream NixOS module users

If you import upstream OpenWhispr's `nix/module.nix`,
`programs.openwhispr.users` keeps its meaning: the listed users join the ydotool
and uinput groups. To use
this flake's module instead, import `nix-openwhispr.nixosModules.default`. Its
`waylandPaste.enable` option, default `true`, turns on ydotool and uinput, as
upstream's module does.
