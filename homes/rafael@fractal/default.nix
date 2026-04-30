{ pkgs, ... }:
{
  modules.home-manager = {
    # Apps
    ghostty.enable = true;
    # yt-dlp.enable = true;
    zed-editor.enable = true;
    # Services
    easyeffects.enable = true;
  };

  home.packages = with pkgs; [
    # Audio interface
    alsa-scarlett-gui
    # Gaming
    umu-launcher
  ];
}
