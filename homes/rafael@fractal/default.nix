{ pkgs, ... }:
{
  modules.home-manager = {
    cursor.enable = true;
    papirus.enable = true;
    plasma-manager.enable = true;

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
    tor-browser
    telegram-desktop
  ];
}
