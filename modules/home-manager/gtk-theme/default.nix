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
    gtk = {
      enable = true;
      gtk3 = {
        enable = true;
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome.gnome-themes-extra;
        };
        extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
      };
      gtk4 = {
        enable = true;
        extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
      };
    };
    qt = {
      enable = true;
      style = {
        name = "adwaita-dark";
        package = pkgs.adwaita-qt;
      };
    };
  };
}
