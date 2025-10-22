{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) user;
  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  cfg = config.modules.nixos.catppuccin;
  homeConfig = config.home-manager.users.${user.name};

  themeConfig = {
    catppuccin = {
      enable = true;
      inherit (cfg) flavor accent;
      cache.enable = true;
    };
  };

  sddmThemeConfig = lib.mkIf config.services.displayManager.sddm.enable {
    catppuccin.sddm = {
      inherit (cfg) flavor accent;
      font = "JetBrainsMono Nerd Font";
      fontSize = "12";
      background = "${inputs.self}/resources/wallpapers/blank_wall.png";
    };
    environment.systemPackages = [ pkgs.nerd-fonts.jetbrains-mono ];
  };

  papirusConfig = lib.mkIf homeConfig.modules.home-manager.papirus.enable {
    modules.home-manager.papirus.package = lib.mkForce pkgs.catppuccin-papirus-folders;
  };

  upperFlavor = utils.capitalizeFirst cfg.flavor;
  upperAccent = utils.capitalizeFirst cfg.accent;
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
    themeName = lib.mkOption {
      type = lib.types.str;
      default = "Catppuccin-${upperFlavor}-${upperAccent}";
      readOnly = true;
    };
    colorScheme = lib.mkOption {
      type = lib.types.str;
      default = builtins.replaceStrings [ "-" ] [ "" ] cfg.themeName;
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      themeConfig
      sddmThemeConfig
      {
        home-manager.users.${user.name}.imports = [
          inputs.catppuccin.homeModules.catppuccin
          themeConfig
          papirusConfig
        ];
      }
    ]
  );
}
