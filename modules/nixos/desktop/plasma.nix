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

    x11AppsScaleThemselves = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        How legacy (Xwayland) applications are scaled, i.e. System Settings >
        Display & Monitor > Legacy Applications (X11):
        - `true`: apply scaling themselves (sharp, but only for apps honouring `Xft.dpi`)
        - `false`: scaled by the system (correct size, but blurry on fractional scales)

        The setting is locked, so it can't be changed from System Settings.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      desktopManager.plasma6.enable = true;
      displayManager.plasma-login-manager.enable = true;
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
        haruna
        ghostty
      ];
      sessionVariables = {
        NIXOS_OZONE_WL = "1"; # Hint Electron apps to use Wayland
        GSK_RENDERER = "gl"; # Fix GTK not rendering when using Vulkan
      };

      # System-wide KDE defaults; `[$i]` marks the key immutable, so it takes
      # precedence over ~/.config/kdeglobals and is greyed out in the GUI
      etc."xdg/kdeglobals".text = ''
        [KScreen]
        XwaylandClientsScale[$i]=${lib.boolToString cfg.x11AppsScaleThemselves}
      '';
    };
  };
}
