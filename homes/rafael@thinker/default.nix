{ pkgs, ... }:
{
  modules.home-manager = {
    # Apps
    ghostty.enable = true;
    yt-dlp.enable = true;
    zed-editor.enable = true;
    # Services
    easyeffects.enable = true;
  };

  programs = {
    chromium = {
      enable = true;
      package = pkgs.google-chrome;
    };
    firefox.enable = true;
  };

  home.packages = with pkgs; [
    # General apps
    krita
  ];
}
