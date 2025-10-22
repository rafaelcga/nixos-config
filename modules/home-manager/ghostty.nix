{ config, lib, ... }:
let
  cfg = config.modules.home-manager.ghostty;
in
{
  options.modules.home-manager.ghostty = {
    enable = lib.mkEnableOption "Enable Ghostty terminal";
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      settings = {
        window-padding-x = 10;
        window-padding-y = 10;
      };
    };
  };
}
