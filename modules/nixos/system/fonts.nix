{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.fonts;
in
{
  options.modules.nixos.fonts = {
    enable = lib.mkEnableOption "Install a default set of fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      liberation_ttf
    ];
  };
}
