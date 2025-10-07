{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.cursor-theme;
in
{
  options.modules.home-manager.cursor-theme = {
    enable = lib.mkEnableOption "Cursor theme configuration";
  };

  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      enable = true;
      name = "Posy_Cursor_Black";
      package = pkgs.posy-cursors;
    };
  };
}
