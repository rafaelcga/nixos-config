{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.papirus;
  papirus =
    if builtins.hasAttr "catppuccin" config then
      pkgs.catppuccin-papirus-folders.override {
        inherit (config.catppuccin) flavor accent;
      }
    else
      pkgs.papirus-icon-theme;
in
{
  options.modules.home-manager.papirus = {
    enable = lib.mkEnableOption "Papirus icon theme configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ papirus ];
  };
}
