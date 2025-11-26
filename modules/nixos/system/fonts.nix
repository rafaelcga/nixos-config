{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.fonts;

  fontDir = "/run/current-system/sw/share/X11/fonts";
in
{
  options.modules.nixos.fonts = {
    enable = lib.mkEnableOption "Install a default set of fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji
        liberation_ttf
        nerd-fonts.jetbrains-mono
        nerd-fonts.zed-mono
      ];
    };

    home-manager.users.${userName}.config.xdg.dataFile."fonts" = {
      source = fontDir;
      force = true;
    };
  };
}
