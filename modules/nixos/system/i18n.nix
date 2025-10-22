{ config, lib, ... }:
let
  cfg = config.modules.nixos.i18n;
in
{
  options.modules.nixos.i18n = {
    locale = lib.mkOption {
      default = "en_IE.UTF-8"; # Irish English (for international locale)
      type = lib.types.str;
      description = "Which glibc valid locale to apply to all options";
    };
    layout = lib.mkOption {
      type = lib.types.str;
      default = "es";
      description = "Keyboard layout";
    };
  };

  config = {
    i18n = {
      defaultLocale = cfg.locale;
      extraLocaleSettings.LC_ALL = cfg.locale;
    };

    services.xserver.xkb.layout = cfg.layout;
    console.keyMap = cfg.layout;
  };
}
