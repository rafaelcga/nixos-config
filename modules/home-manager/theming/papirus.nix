{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.papirus;
in
{
  options.modules.home-manager.papirus = {
    enable = lib.mkEnableOption "Enable Papirus Icon Theme";

    name = lib.mkOption {
      type = lib.types.str;
      default = "Papirus-Dark";
      description = "Theme name";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.papirus-icon-theme;
      description = "Theme package";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    gtk.iconTheme = { inherit (cfg) name package; };
  };
}
