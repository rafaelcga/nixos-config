{
  config,
  lib,
  pkgs,
  catppuccinTheme,
  ...
}:
let
  cfg = config.modules.home-manager.catppuccin;
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
        name = "Catppuccin";
        package = pkgs.magnetic-catppuccin-gtk.override {
          accent = [ catppuccinTheme.accent ];
          tweaks = [ catppuccinTheme.flavor ];
        };
      };
    };
  };
}
