{ config, lib, ... }:
let
  cfg = config.modules.nixos.locale;
in
{
  options.modules.nixos.locale = {
    default = lib.mkOption {
      default = "en_IE.UTF-8"; # Irish English (for international locale)
      type = lib.types.str;
      description = "Which glibc valid locale to apply to all options";
    };
    layout = lib.mkOption {
      type = lib.types.str;
      default = "es";
      description = "Keyboard layout";
    };
    timeZone = lib.mkOption {
      default = "Europe/Madrid";
      type = lib.types.str;
      description = "Time zone";
    };
  };

  config = {
    i18n = {
      defaultLocale = cfg.default;
      extraLocaleSettings.LC_ALL = cfg.default;
    };

    services.xserver.xkb.layout = cfg.layout;
    console.keyMap = cfg.layout;

    time.timeZone = cfg.timeZone;
  };
}
