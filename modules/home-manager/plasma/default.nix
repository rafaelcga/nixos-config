{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.home-manager.plasma;
  usesCatppuccin = config.catppuccin.enable or false;
  upperFlavor = lib.local.capitalizeFirst config.catppuccin.flavor or "";
  upperAccent = lib.local.capitalizeFirst config.catppuccin.accent or "";

  globalTheme = if usesCatppuccin then "Catppuccin-${upperFlavor}-${upperAccent}" else "Breeze-Dark";
  colorScheme = builtins.replaceStrings [ "-" ] [ "" ] globalTheme;
  widgetStyle = "Darkly";

  pastelIconPath = "${inputs.self}/resources/splash/nix-snowflake-rainbow-pastel.svg";
  wallpaperPath = "${inputs.self}resources/wallpapers/nebula.jpg";

  fontConfig = {
    family = "JetBrainsMono Nerd Font";
    pointSize = 12;
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
        windowDecorations = {
          theme = "Breeze";
          library = "org.kde.breeze";
        };
        splashScreen.theme = globalTheme;
        wallpaper = builtins.toString wallpaperPath;
        wallpaperFillMode = "preserveAspectCrop";
      };
      kwin = {
        effects.shakeCursor.enable = false;
        titlebarButtons = {
          left = [
            "more-window-actions"
          ];
          right = [
            "minimize"
            "maximize"
            "close"
          ];
        };
      };
      kscreenlocker = {
        autoLock = false;
        appearance.wallpaper = builtins.toString wallpaperPath;
      };
      fonts = {
        general = fontConfig;
        toolbar = fontConfig;
        menu = fontConfig;
        windowTitle = fontConfig;
      };
      input.keyboard.numlockOnStartup = "on";
      powerdevil.AC = {
        autoSuspend.action = "nothing";
        dimDisplay.enable = false;
        turnOffDisplay.idleTimeout = "never";
      };
      session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
      krunner = {
        position = "center";
        historyBehavior = "enableAutoComplete";
      };
      shortcuts = {
        "services/org.kde.krunner.desktop"."_launch" = "Meta"; # KRunner launch
        "plasmashell"."activate application launcher" = [ ]; # Deactivate app launcher
      };
      # Check ${plasma-manager}/modules/widgets or widget names in
      # ~/.config/plasma-org.kde.plasma.desktop-appletsrc
      panels = [
        {
          height = 28;
          lengthMode = "fill";
          location = "top";
          alignment = "center";
          hiding = "none";
          floating = false;
          opacity = "opaque";
          screen = 0;
          widgets = [
            {
              kickoff = {
                icon = builtins.toString pastelIconPath;
              };
            }
            {
              pager.general = {
                displayedText = "desktopNumber";
                showWindowOutlines = false;
              };
            }
            {
              panelSpacer.expanding = true;
            }
            {
              digitalClock.date = {
                enable = true;
                format.custom = "ddd d MMMM";
                position = "besideTime";
              };
            }
            {
              panelSpacer.expanding = true;
            }
            {
              keyboardLayout.displayStyle = "label";
            }
            {
              systemTray = {
                icons = {
                  spacing = "medium";
                  scaleToFit = true;
                };
                items = {
                  hidden = [
                    "org.kde.plasma.brightness"
                    "org.kde.plasma.clipboard"
                  ];
                };
              };
            }
          ];
        }
      ];
      # Configurations applied to config files; check example home.nix in
      # https://github.com/nix-community/plasma-manager/blob/trunk/examples/home.nix
      # To easily check which to change, you can also run their `rc2nix` tool:
      # `nix run github:nix-community/plasma-manager`
      configFile = {
        kdeglobals = {
          KDE = { inherit widgetStyle; };
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
    home.packages =
      with pkgs;
      [
        darkly
        darkly-qt5
        nerd-fonts.jetbrains-mono
      ]
      ++ lib.optionals usesCatppuccin [
        catppuccin-kde
      ];
    qt.platformTheme.name = "qtct"; # Required by Darkly
  };
}
