# nix-darwin module for OpenWhispr. It installs the application into the system
# profile. The per-user launch agent is managed by the Home Manager module.
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
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
