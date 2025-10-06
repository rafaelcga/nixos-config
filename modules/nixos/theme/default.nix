{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.theme;
  flavor = "frappe";
  accent = "teal";
in
{
  options.modules.nixos.theme = {
    enable = lib.mkEnableOption "Catppuccin color theme flake";
  };

  config = lib.mkIf cfg.enable {
    catppuccin = {
      enable = true;
      inherit flavor accent;
      cache.enable = true;
    };

  };
}
