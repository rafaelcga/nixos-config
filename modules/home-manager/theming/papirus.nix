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
  };

  config = lib.mkIf cfg.enable {
    # .local/share/icons/Papirus
    xdg.dataFile =
      let
        variants = [
          ""
          "-Dark"
          "-Light"
        ];

        mkVariant =
          variant:
          let
            source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";
          in
          lib.nameValuePair "icons/Papirus${variant}" { inherit source; };
      in
      lib.genAttrs' variants mkVariant;

    gtk = {
      enable = true;
      iconTheme = {
        name = lib.mkDefault "Papirus";
        package = lib.mkDefault pkgs.papirus-icon-theme;
      };
    };
  };
}
