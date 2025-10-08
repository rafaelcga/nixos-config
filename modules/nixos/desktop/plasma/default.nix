{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.desktop.plasma;
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
        konsole
        okular
        kate
      ];
      systemPackages = with pkgs; [
        ghostty
        papers
        celluloid
        cosmic-edit
      ];
    };
    hardware.bluetooth.enable = true;
  };
}
