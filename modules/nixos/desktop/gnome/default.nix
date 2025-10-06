{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.desktop.gnome;
  extensions = with pkgs; [ gnomeExtensions.appindicator ];
  extensionsUuid = builtins.map (extension: extension.extensionUuid) extensions;
in
{
  options.modules.nixos.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME configuration";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-user-docs
      baobab
      decibels
      epiphany
      gnome-characters
      gnome-clocks
      gnome-console
      gnome-contacts
      gnome-font-viewer
      gnome-logs
      gnome-maps
      gnome-music
      gnome-system-monitor
      gnome-weather
      gnome-connections
      gnome-software
      simple-scan
      snapshot
      totem
      yelp
      evince
      geary
    ];
    # Add packages replacing GNOME ones
    environment.systemPackages =
      with pkgs;
      [
        ghostty
        papers
        cosmic-store
      ]
      ++ extensions;
    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "ghostty";
    };
    programs.dconf.profiles.user.databases = [
      {
        settings = {
          "org/gnome/mutter" = {
            experimental-features = [
              "scale-monitor-framebuffer" # Enables fractional scaling (125% 150% 175%)
              "variable-refresh-rate" # Enables Variable Refresh Rate (VRR) on compatible displays
              "xwayland-native-scaling" # Scales Xwayland applications to look crisp on HiDPI screens
            ];
          };
          "org/gnome/shell" = {
            enabled-extensions = extensionsUuid;
          };
        };
      }
    ];
  };
}
