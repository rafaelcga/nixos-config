{ pkgs, ... }:
{
  programs = {
    chromium = {
      enable = true;
      package = pkgs.google-chrome;
    };
    firefox.enable = true;
  };
  home.packages = with pkgs; [
    discord
    telegram-desktop
  ];
}
