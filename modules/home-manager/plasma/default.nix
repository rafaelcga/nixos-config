{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.plasma;
  usesCatppuccin = config.catppuccin.enable or false;
  colorScheme =
    if usesCatppuccin then
      "Catppuccin"
      + (lib.local.capitalizeFirst config.catppuccin.flavor)
      + (lib.local.capitalizeFirst config.catppuccin.accent)
    else
      "BreezeDark";
  catppuccinKde = lib.mkIf usesCatppuccin (
    pkgs.catppuccin-kde.override {
      flavour = [ config.catppuccin.flavor ];
      accents = [ config.catppuccin.accent ];
    }
  );
in
{
  options.modules.home-manager.plasma = {
    enable = lib.mkEnableOption "Plasma customization configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.plasma = {
      enable = true;
      workspace = {
        inherit colorScheme;
      };
    };
    home = lib.mkIf usesCatppuccin {
      packages = [ catppuccinKde ];
    };
  };
}
