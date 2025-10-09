{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.plasma;
  usesCatppuccin = config.catppuccin.enable or false;
  upperFlavor = lib.local.capitalizeFirst config.catppuccin.flavor or "";
  upperAccent = lib.local.capitalizeFirst config.catppuccin.accent or "";

  colorScheme = if usesCatppuccin then "Catppuccin${upperFlavor}${upperAccent}" else "BreezeDark";
  splashTheme = if usesCatppuccin then "Catppuccin-${upperFlavor}-${upperAccent}" else "Breeze";

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
        splashScreen.theme = splashTheme;
        windowDecorations = {
          theme = themeConfig.name;
          inherit (themeConfig) library;
        };
      };
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
      krunner = {
        position = "center";
        historyBehavior = "enableAutoComplete";
      };
      shortcuts = {
        "services/org.kde.krunner.desktop"."_launch" = "Meta"; # KRunner launch
        "plasmashell"."activate application launcher" = [ ]; # Deactivate app launcher
      };
      # Configurations applied to config files; check example home.nix in
      # https://github.com/nix-community/plasma-manager/blob/trunk/examples/home.nix
      # To easily check which to change, you can also run their `rc2nix` tool:
      # `nix run github:nix-community/plasma-manager`
      configFile = {
        kdeglobals = {
          KDE.widgetStyle = themeConfig.name;
          General = {
            TerminalApplication = "ghostty";
            TerminalService = "Ghostty.desktop";
          };
        };
        # Order plugins so that (already open) Windows come up before Applications
        krunnerrc."Plugins/Favorites".plugins =
          "krunner_sessions,krunner_powerdevil,windows,krunner_services,krunner_systemsettings";
      };
    };
    home = lib.mkIf usesCatppuccin {
      packages = with pkgs; [
        darkly
        darkly-qt5
        catppuccin-kde
        nerd-fonts.jetbrains-mono
      ];
    };
    qt.platformTheme.name = "qtct";
  };
}
