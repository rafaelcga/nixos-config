{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.cursor;
in
{
  options.modules.home-manager.cursor = {
    enable = lib.mkEnableOption "Enable cursor theming";
    name = lib.mkOption {
      type = lib.types.str;
      default = "Adwaita";
      description = "Cursor theme name";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.adwaita-icon-theme;
      description = "Cursor theme package";
    };
    size = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "Cursor size";
    };
  };

  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      inherit (cfg) name package size;
      enable = true;
      dotIcons.enable = true;
      x11.enable = true;
      gtk.enable = true;
      hyprcursor.enable = true;
      sway.enable = true;
    };
  };
}
