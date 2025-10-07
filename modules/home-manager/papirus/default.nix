{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.papirus;
  papirus-folders = pkgs.catppuccin-papirus-folders.override {
    inherit (config.catppuccin) flavor accent;
  };
in
{
  options.modules.home-manager.papirus = {
    enable = lib.mkEnableOption "Papirus icon theme configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      papirus-folders
    ];
  };
}
