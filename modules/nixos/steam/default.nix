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
    hardware.steam-hardware.enable = true; # Steam controllers and such
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
  };

  # Proton CachyOS/GE variables
  environment.sessionVariables = {
    # Upscaling
    PROTON_DLSS_UPGRADE = 1;
    PROTON_NVIDIA_LIBS = 1;
    PROTON_FSR4_UPGRADE = 1;
    PROTON_XESS_UPGRADE = 1;
    # Compositor
    PROTON_ENABLE_WAYLAND = 1;
    PROTON_NO_WM_DECORATION = 1;
    # CPU
    PROTON_USE_NTSYNC = 1;
  };
}
