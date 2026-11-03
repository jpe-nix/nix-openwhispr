# NixOS module for OpenWhispr. It installs the application and, when
# waylandPaste.enable is true, sets up the ydotool daemon and uinput access that
# Wayland keystroke injection needs. Mirrors upstream's nix/module.nix, with the
# package defaulting to this flake's output.
{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.openwhispr;
in
{
  options.programs.openwhispr = {
    enable = lib.mkEnableOption "OpenWhispr voice dictation app";

    package = lib.mkPackageOption self.packages.${pkgs.stdenv.hostPlatform.system} "openwhispr" {
      pkgsText = "nix-openwhispr.packages.\${system}";
      example = lib.literalExpression "pkgs.openwhispr";
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "alice" ];
      description = "Users added to the ydotool and uinput groups for Wayland auto-paste. Applies only when waylandPaste.enable is true. Leave empty to manage group membership yourself.";
    };

    waylandPaste.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Enable the ydotool daemon and uinput access used for Wayland keystroke injection.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ cfg.package ];
      }

      (lib.mkIf cfg.waylandPaste.enable {
        # The ydotool daemon and its socket group. programs.ydotool does not load
        # the uinput module, which OpenWhispr's uinput paste backend needs.
        programs.ydotool.enable = true;
        hardware.uinput.enable = true;

        users.users = lib.genAttrs cfg.users (_: {
          extraGroups = [
            config.programs.ydotool.group
            "uinput"
          ];
        });
      })
    ]
  );
}
