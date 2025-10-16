{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.nixos.desktop.plasma;
  usesCatppuccin = config.catppuccin.enable or false;

  blankWallpaperPath = "${inputs.self}/resources/wallpapers/blank_wall.png";
in
{
  options.modules.nixos.desktop.plasma = {
    enable = lib.mkEnableOption "KDE Plasma configuration";
  };

  config = lib.mkIf cfg.enable {
    services = {
      desktopManager.plasma6.enable = true;
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    environment = {
      plasma6.excludePackages = with pkgs.kdePackages; [
        kate
        okular
        konsole
        discover
      ];
      systemPackages = with pkgs; [
        papers
        ghostty
        celluloid
        cosmic-edit
        cosmic-store
        nerd-fonts.jetbrains-mono # Install font globally for SDDM
      ];
      sessionVariables.NIXOS_OZONE_WL = "1"; # Hint Electron apps to use Wayland
    };
    programs.partition-manager.enable = true;
    hardware.bluetooth.enable = true;

    catppuccin = lib.mkIf usesCatppuccin {
      sddm = {
        inherit (config.catppuccin) flavor accent;
        font = "JetBrainsMono Nerd Font";
        fontSize = "12";
        background = blankWallpaperPath;
      };
    };
  };
}
