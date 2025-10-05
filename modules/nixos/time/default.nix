{ config, lib, ... }:
let
  cfg = config.modules.nixos.time;
in
{
  options.modules.nixos.time = {
    enable = lib.mkEnableOption "time zone configuration";
    locale = lib.mkOption {
      default = "Europe/Madrid";
      type = lib.types.str;
      description = "Desired time zone";
    };
  };

  config = lib.mkIf cfg.enable {
    time.timeZone = cfg.locale;
  };
}
