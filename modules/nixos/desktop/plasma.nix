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
      displayManager.plasma-login-manager.enable = true;
    };
    hardware.bluetooth.enable = true;

    # Fix Plasma Login Manager missing icons
    systemd.tmpfiles.settings."10-icons-symlink" = {
      "/usr/share/icons"."L+".argument = "/run/current-system/sw/share/icons";
    };

    programs.partition-manager.enable = true;
    environment = {
      plasma6.excludePackages = with pkgs.kdePackages; [
        kate
        okular
        konsole
        discover
      ];
      systemPackages = with pkgs; [
        ghostty
        cosmic-store
      ];
      sessionVariables.NIXOS_OZONE_WL = "1"; # Hint Electron apps to use Wayland
    };
  };
}
