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
  };

  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      enable = true;
      name = "Adwaita";
      size = 32;
      package = pkgs.adwaita-icon-theme;
      x11.enable = true;
      gtk.enable = true;
      hyprcursor.enable = true;
    };
    programs = lib.mkIf usesPlasma {
      plasma.workspace.cursor = {
        theme = config.home.pointerCursor.name;
        inherit (config.home.pointerCursor) size;
      };
    };
  };
}
