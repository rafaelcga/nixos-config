{ pkgs, ... }:
{
  modules.home-manager = {
    # Theming
    cursor.enable = true;
    papirus.enable = true;
    # Apps
    ghostty.enable = true;
    yt-dlp.enable = true;
    zed-editor.enable = true;
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
