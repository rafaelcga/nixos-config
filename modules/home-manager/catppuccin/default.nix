{
  config,
  lib,
  utils,
  pkgs,
  catppuccinTheme,
  ...
}:
let
  cfg = config.modules.home-manager.catppuccin;
  themeName =
    "Catppuccin-GTK-"
    + utils.capitalizeFirst catppuccinTheme.accent
    + "-Dark-"
    + utils.capitalizeFirst catppuccinTheme.flavor;
in
{
  options.modules.home-manager.catppuccin = {
    enable = lib.mkEnableOption "Catppuccin color theme flake";
  };

  config = lib.mkIf cfg.enable {
    catppuccin = {
      enable = true;
      inherit (catppuccinTheme) flavor accent;
      cache.enable = true;
    };
    gtk = {
      enable = true;
      theme = {
        name = themeName;
        package = pkgs.magnetic-catppuccin-gtk.override {
          accent = [ catppuccinTheme.accent ];
          tweaks = [ catppuccinTheme.flavor ];
        };
      };
    };
  };
}
