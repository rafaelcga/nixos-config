{
  inputs,
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = config.modules.home-manager.plasma-manager;
  catppuccinModule = osConfig.modules.nixos.catppuccin;

  panelIconPath = "${inputs.self}/resources/splash/nix-snowflake-rainbow-pastel.svg";
  wallpaperPath = "${inputs.self}/resources/wallpapers/nebula.jpg";

  fontConfig = { inherit (cfg.font) family pointSize; };
in
{
  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  options.modules.home-manager.plasma-manager = {
    enable = lib.mkEnableOption "Enable plasma-manager flake";
    windowDecorations = {
      theme = lib.mkOption {
        type = lib.types.str;
        default = "Breeze";
        description = "Window decorations theme";
      };
      library = lib.mkOption {
        type = lib.types.str;
        default = "org.kde.breeze";
        description = "Window decorations library";
      };
    };
    widgetStyle = lib.mkOption {
      type = lib.types.str;
      default = "Darkly";
      description = "Widget style";
    };
    colorScheme = lib.mkOption {
      type = lib.types.str;
      default = builtins.replaceStrings [ "-" ] [ "" ] cfg.splashTheme;
      description = "Color scheme";
    };
    splashTheme = lib.mkOption {
      type = lib.types.str;
      default = "Breeze-Dark";
      description = "Splash screen theme";
    };
    font = {
      family = lib.mkOption {
        type = lib.types.str;
        default = "JetBrainsMono Nerd Font";
        description = "Desktop environment font";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.nerd-fonts.jetbrains-mono;
        description = "Desktop environment font's package";
      };
      pointSize = lib.mkOption {
        type = lib.types.int;
        default = 12;
        description = "Desktop environment font size";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.plasma = {
      enable = true;

      workspace = {
        inherit (cfg) windowDecorations colorScheme;
        splashScreen.theme = cfg.splashTheme;
        wallpaper = wallpaperPath;
        wallpaperFillMode = "preserveAspectCrop";
      };

      kwin = {
        effects.shakeCursor.enable = false;
        titlebarButtons = {
          left = [ "more-window-actions" ];
          right = [
            "minimize"
            "maximize"
            "close"
          ];
        };
      };

      krunner = {
        position = "center";
        historyBehavior = "enableAutoComplete";
      };
      shortcuts = {
        "services/org.kde.krunner.desktop"."_launch" = "Meta"; # KRunner launch
        "plasmashell"."activate application launcher" = [ ]; # Deactivate app launcher
      };

      kscreenlocker = {
        autoLock = false;
        appearance.wallpaper = wallpaperPath;
      };
      input.keyboard.numlockOnStartup = "on";
      powerdevil.AC = {
        autoSuspend.action = "nothing";
        dimDisplay.enable = false;
        turnOffDisplay.idleTimeout = "never";
      };
      session.sessionRestore = {
        restoreOpenApplicationsOnLogin = "startWithEmptySession";
      };

      # Configurations applied to config files; check example home.nix in
      # https://github.com/nix-community/plasma-manager/blob/trunk/examples/home.nix
      # To easily check which to change, you can also run their `rc2nix` tool:
      # `nix run github:nix-community/plasma-manager`
      configFile = {
        kdeglobals = {
          KDE.widgetStyle = cfg.widgetStyle;
          General = {
            TerminalApplication = "ghostty";
            TerminalService = "Ghostty.desktop";
          };
        };
        # Order plugins so that (already open) Windows come up before Applications
        krunnerrc."Plugins/Favorites".plugins =
          "krunner_sessions,krunner_powerdevil,windows,krunner_services,krunner_systemsettings";
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
                icon = panelIconPath;
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

      fonts = {
        general = fontConfig;
        toolbar = fontConfig;
        menu = fontConfig;
        windowTitle = fontConfig;
      };
    };

    home.packages =
      with pkgs;
      [ cfg.font.package ]
      ++ lib.optionals (cfg.widgetStyle == "Darkly") [
        darkly
        darkly-qt5
      ]
      ++ lib.optionals catppuccinModule.enable [
        catppuccin-kde
      ];
    # Required by Darkly
    qt.platformTheme.name = lib.mkIf (cfg.widgetStyle == "Darkly") "qtct";

    modules.home-manager.plasma-manager = lib.mkIf catppuccinModule.enable {
      colorScheme = lib.mkForce catppuccinModule.colorScheme;
      splashTheme = lib.mkForce catppuccinModule.themeName;
    };
  };
}
