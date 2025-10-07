{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.theme;
in
{
  options.modules.nixos.theme = {
    enable = lib.mkEnableOption "Catppuccin color theme flake";
    flavor = lib.mkOption {
      type = lib.types.enum [
        "latte"
        "frappe"
        "macchiato"
        "mocha"
      ];
      default = "frappe";
      description = "Catppuccin theme flavor (latte, frappe, macchiato, mocha)";
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
      description = "Catppuccin accent";
    };
  };

  config = lib.mkIf cfg.enable {
    catppuccin = {
      enable = true;
      inherit (cfg) flavor accent;
      cache.enable = true;
    };

  };
}
