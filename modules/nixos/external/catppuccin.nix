{
  inputs,
  config,
  lib,
  pkgs,
  hmConfig,
  userName,
  ...
}:
let
  inherit (hmConfig.modules.home-manager) papirus plasma-manager;

  cfg = config.modules.nixos.catppuccin;
in
{
  imports = [ inputs.catppuccin.nixosModules.catppuccin ];

  options.modules.nixos.catppuccin = {
    enable = lib.mkEnableOption "Enable Catppuccin theme flake";

    flavor = lib.mkOption {
      type = lib.types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = "frappe";
      description = "Theme flavor (latte, frappe, macchiato, mocha)";
    };

    accent = lib.mkOption {
      type = lib.types.enum [
        "blue"
        "flamingo"
        "green"
        "lavender"
        "maroon"
        "mauve"
        "peach"
        "pink"
        "red"
        "rosewater"
        "sapphire"
        "sky"
        "teal"
        "yellow"
      ];
      default = "teal";
      description = "Accent color";
    };

    themeName =
      let
        utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };
        upperFlavor = utils.capitalizeFirst cfg.flavor;
        upperAccent = utils.capitalizeFirst cfg.accent;
      in
      lib.mkOption {
        type = lib.types.str;
        default = "Catppuccin-${upperFlavor}-${upperAccent}";
        readOnly = true;
      };

    colorScheme = lib.mkOption {
      type = lib.types.str;
      default = lib.replaceStrings [ "-" ] [ "" ] cfg.themeName;
      readOnly = true;
    };
  };

  config =
    let
      themeConfig = {
        catppuccin = {
          enable = true;
          inherit (cfg) flavor accent;
          cache.enable = true;
        };
      };
    in
    lib.mkIf cfg.enable (
      lib.mkMerge [
        themeConfig
        (lib.mkIf config.services.displayManager.sddm.enable {
          catppuccin.sddm = {
            enable = true;
            font = "JetBrainsMono Nerd Font";
            fontSize = "12";
            background = "${inputs.self}/resources/wallpapers/blank_wall.png";
          };
          fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
        })
        {
          home-manager.users.${userName} = {
            imports = [ inputs.catppuccin.homeModules.catppuccin ];

            config = lib.mkMerge [
              themeConfig
              (lib.mkIf papirus.enable {
                catppuccin.gtk.icon.enable = true;
              })
              (lib.mkIf plasma-manager.enable {
                home.packages = [ pkgs.catppuccin-kde ];
                modules.home-manager.plasma-manager = {
                  colorScheme = lib.mkForce cfg.colorScheme;
                  splashTheme = lib.mkForce cfg.themeName;
                };
              })
            ];
          };
        }
      ]
    );
}
