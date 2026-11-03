# Renames from the v1 option names. Each old option still works and emits a
# warning that names its replacement. Assigning a package to `models` still
# works through a coercion in options.nix that warns; see docs/MIGRATION.md.
{ lib, ... }:
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "openwhispr" "autoStart" ]
      [ "programs" "openwhispr" "autostart" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "openwhispr" "modelBootstrap" ]
      [ "programs" "openwhispr" "models" "bootstrap" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "openwhispr" "localTranscriptionProvider" ]
      [ "programs" "openwhispr" "transcription" "provider" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "openwhispr" "whisperModel" ]
      [ "programs" "openwhispr" "transcription" "whisperModel" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "openwhispr" "parakeetModel" ]
      [ "programs" "openwhispr" "transcription" "parakeetModel" ]
    )
  ];
}
