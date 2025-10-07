{ config, lib, ... }:
let
  cfg = config.modules.nixos.keyboard;
in
{
  options.modules.nixos.keyboard = {
    enable = lib.mkEnableOption "Keyboard options";
    layout = lib.mkOption {
      type = lib.types.str;
      default = "es";
      description = "Keyboard layout";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.xkb.layout = cfg.layout;
    console.keyMap = cfg.layout;
  };
}
