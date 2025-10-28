{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) user;
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

    systemd.services.link-system-fonts = {
      description = "Links the nix-store font directory to $XDG_DATA_HOME/fonts";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = user.name;
        Group = user.group;
      };
      script = ''
        set -euo pipefail

        mkdir -p "$XDG_DATA_HOME"
        ln -s "${fontDir}" "$XDG_DATA_HOME/fonts"
      '';
    };
  };
}
