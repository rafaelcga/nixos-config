{ config, lib, ... }:
let
  cfg = config.modules.nixos.time;
in
{
  options.modules.nixos.time = {
    locale = lib.mkOption {
      default = "Europe/Madrid";
      type = lib.types.str;
      description = "Time zone";
    };
  };

  config = {
    time.timeZone = cfg.locale;
  };
}
