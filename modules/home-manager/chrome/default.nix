{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.chrome;
in
{
  options.modules.home-manager.chrome = {
    enable = lib.mkEnableOption "Google Chrome settings";
  };

  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.google-chrome;
      # TODO: declarative user settings
    };
  };
}
