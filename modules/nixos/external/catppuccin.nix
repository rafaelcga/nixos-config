{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) user;
  cfg = config.modules.nixos.catppuccin;

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
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      themeConfig
      sddmThemeConfig
      {
        home-manager.users.${user.name}.imports = [
          themeConfig
        ];
      }
    ]
  );
}
