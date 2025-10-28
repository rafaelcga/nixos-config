{ pkgs, ... }:
{
  modules.home-manager = {
    # Theming
    cursor.enable = true;
    papirus.enable = true;
    plasma-manager.enable = true;
    # Apps
    ghostty.enable = true;
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
    telegram-desktop
    # Gaming
    umu-launcher
    heroic
  ];
}
