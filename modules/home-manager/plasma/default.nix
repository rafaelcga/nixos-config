{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.plasma;
  usesCatppuccin = config.catppuccin.enable or false;
  colorScheme =
    if usesCatppuccin then
      "Catppuccin"
      + (lib.local.capitalizeFirst config.catppuccin.flavor)
      + (lib.local.capitalizeFirst config.catppuccin.accent)
    else
      "BreezeDark";
  catppuccinKde = lib.mkIf usesCatppuccin (
    pkgs.catppuccin-kde.override {
      flavour = [ config.catppuccin.flavor ];
      accents = [ config.catppuccin.accent ];
    }
  );
  fontConfig = {
    family = "JetBrainsMono Nerd Font";
    pointSize = 12;
  };
  themeConfig = {
    name = "Darkly";
    library = "org.kde.darkly";
  };
in
{
  options.modules.home-manager.plasma = {
    enable = lib.mkEnableOption "Plasma customization configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.plasma = {
      enable = true;
      workspace = {
        inherit colorScheme;
        splashScreen.theme = "None"; # No splash screen
        windowDecorations = {
          theme = themeConfig.name;
          inherit (themeConfig) library;
        };
      };
      configFile.kdeglobals.KDE.widgetStyle = config.programs.plasma.workspace.windowDecorations.theme;
      fonts = {
        general = fontConfig;
        toolbar = fontConfig;
        menu = fontConfig;
        windowTitle = fontConfig;
      };
      input.keyboard.numlockOnStartup = "on";
      kscreenlocker.autoLock = false;
      powerdevil.AC = {
        autoSuspend.action = "nothing";
        dimDisplay.enable = false;
        turnOffDisplay.idleTimeout = "never";
      };
    };
    home = lib.mkIf usesCatppuccin {
      packages = with pkgs; [
        darkly
        darkly-qt5
        catppuccinKde
        nerd-fonts.jetbrains-mono
      ];
    };
    qt.platformTheme.name = "qtct";
  };
}
