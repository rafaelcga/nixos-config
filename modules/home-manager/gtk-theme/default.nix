{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.gtk-theme;
in
{
  options.modules.home-manager.gtk-theme = {
    enable = lib.mkEnableOption "GTK theming configuration";
  };

  config = lib.mkIf cfg.enable {
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
    gtk = {
      enable = true;
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
    qt = lib.mkIf (!config.catppuccin.enable) {
      enable = true;
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };
  };
}
