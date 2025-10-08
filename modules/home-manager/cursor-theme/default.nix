{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.cursor-theme;
  usesPlasma = config.programs.plasma.enable or false;
in
{
  options.modules.home-manager.cursor-theme = {
    enable = lib.mkEnableOption "Cursor theme configuration";
    size = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "Cursor size";
    };
  };

  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      inherit (cfg) size;
      enable = true;
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      x11.enable = true;
      gtk.enable = true;
      hyprcursor.enable = true;
    };
    programs = lib.mkIf usesPlasma {
      plasma.workspace.cursor = {
        inherit (cfg) size;
        theme = config.home.pointerCursor.name;
      };
    };
  };
}
