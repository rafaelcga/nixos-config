{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.plasma;
in
{
  options.modules.nixos.plasma = {
    enable = lib.mkEnableOption "Enable KDE Plasma desktop";
  };

  config = lib.mkIf cfg.enable {
    services = {
      desktopManager.plasma6.enable = true;
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    hardware.bluetooth.enable = true;

    programs.partition-manager.enable = true;
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
      ];
      sessionVariables.NIXOS_OZONE_WL = "1"; # Hint Electron apps to use Wayland
    };
  };
}
