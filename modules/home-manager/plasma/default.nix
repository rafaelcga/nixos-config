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
  globalThemeName = if usesCatppuccin then "Catppuccin-${upperFlavor}-${upperAccent}" else "";

  nixosLogoPath = ../../../resources/icons/nix-snowflake-rainbow-pastel.png;
  originalLogoPath = "/share/plasma/look-and-feel/${globalThemeName}/contents/splash/images/Logo.png";
  catppuccinKde = lib.mkIf usesCatppuccin (
    (pkgs.catppuccin-kde.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        cp ${nixosLogoPath} $out${originalLogoPath}
      '';
    })).override
      {
        flavour = [ config.catppuccin.flavor ];
        accents = [ config.catppuccin.accent ];
      }
  );
  splashTheme = if usesCatppuccin then "${globalThemeName}-splash" else "Breeze";

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
