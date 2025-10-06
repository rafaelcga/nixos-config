{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.icons;
in
{
  options.modules.home-manager.icons = {
    enable = lib.mkEnableOption "Papirus icon theme configuration";
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      iconTheme = pkgs.papirus-icon-theme;
    };
  };
}
