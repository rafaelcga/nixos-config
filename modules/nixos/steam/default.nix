{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.steam;
in
{
  options.modules.nixos.steam = {
    enable = lib.mkEnableOption "Steam configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      package = pkgs.steam.override {
        extraPkgs =
          pkgs': with pkgs'; [
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib # Provides libstdc++.so.6
            libkrb5
            keyutils
            # Add other libraries as needed
            adwaita-icon-theme
          ];
      };
    };
    xdg.icons.fallbackCursorThemes = [ "Adwaita" ];
    hardware.steam-hardware.enable = true;
  };
}
