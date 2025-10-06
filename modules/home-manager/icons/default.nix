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
    home.packages = [ pkgs.papirus-folders ];
    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus";
        package = pkgs.papirus-icon-theme;
      };
    };
  };
}
