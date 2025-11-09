{
  config,
  lib,
  pkgs,
  hmConfig,
  ...
}:
let
  inherit (hmConfig.home) pointerCursor;
  cfg = config.modules.nixos.steam;
in
{
  options.modules.nixos.steam = {
    enable = lib.mkEnableOption "Enable Steam";

    protonWayland.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Enable Wayland driver for Proton";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.steam-hardware.enable = true; # Steam controllers and such
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraPackages =
        with pkgs;
        [
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
        ]
        # Pointer cursor theme
        ++ lib.optionals pointerCursor.enable [
          pointerCursor.package
        ];
    };

    # Proton CachyOS/GE variables
    environment.sessionVariables = lib.mkMerge [
      {
        # Upscaling
        PROTON_DLSS_UPGRADE = 1;
        PROTON_NVIDIA_LIBS = 1;
        PROTON_FSR4_UPGRADE = 1;
        PROTON_XESS_UPGRADE = 1;
        # Compositor
        PROTON_NO_WM_DECORATION = 1;
        # CPU
        PROTON_USE_NTSYNC = 1;
      }
      (lib.mkIf cfg.protonWayland.enable {
        PROTON_ENABLE_WAYLAND = 1;
      })
    ];
  };
}
