{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.papirus;
  usesPlasma = config.programs.plasma.enable or false;
  usesCatppuccin = config.catppuccin.enable or false;
in
{
  options.modules.home-manager.papirus = {
    enable = lib.mkEnableOption "Papirus icon theme configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (if usesCatppuccin then pkgs.catppuccin-papirus-folders else pkgs.papirus-icon-theme)
    ];
    programs = lib.mkIf usesPlasma {
      plasma.workspace.iconTheme = "Papirus-Dark";
    };
  };
}
