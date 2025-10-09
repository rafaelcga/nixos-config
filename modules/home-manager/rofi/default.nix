{ config, lib, ... }:
let
  cfg = config.modules.home-manager.rofi;
in
{
  options.modules.home-manager.rofi = {
    enable = lib.mkEnableOption "Rofi launcher configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.rofi = {
      enable = true;
    };
  };
}
