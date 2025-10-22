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
  };

  config = {
    i18n = {
      defaultLocale = cfg.locale;
      extraLocaleSettings.LC_ALL = cfg.locale;
    };
  };
}
