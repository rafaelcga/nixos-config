{
  config,
  lib,
  catppuccinTheme,
  ...
}:
let
  cfg = config.modules.nixos.catppuccin;
in
{
  options.modules.nixos.catppuccin = {
    enable = lib.mkEnableOption "Catppuccin color theme flake";
  };

  config = lib.mkIf cfg.enable {
    catppuccin = {
      enable = true;
      inherit (catppuccinTheme) flavor accent;
      cache.enable = true;
    };
  };
}
