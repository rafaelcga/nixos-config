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

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.papirus-icon-theme;
      description = "Icon package";
    };
  };

  config = lib.mkIf cfg.enable {
    # Link to .local/share/icons for Flatpaks
    xdg.dataFile =
      let
        themeName = config.gtk.iconTheme.name;
        isPapirus = (lib.match "Papirus.*" themeName) != null;
      in
      lib.mkIf isPapirus {
        "icons/${themeName}" = {
          source = "${cfg.package}/share/icons/${themeName}";
        };
      };

    gtk = {
      enable = true;
      iconTheme = {
        name = lib.mkDefault "Papirus";
        package = lib.mkForce cfg.package;
      };
    };
  };
}
