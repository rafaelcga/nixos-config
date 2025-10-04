{ config, lib, ... }:
let
  cfg = config.modules.nixos.i18n;
in
{
  options.modules.nixos.i18n = {
    enable = lib.mkEnableOption "localization configuration";
    locale = lib.mkOption {
      default = "en_IE.UTF-8"; # Irish English (for international locale)
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    i18n = {
      defaultLocale = cfg.locale;
      extraLocaleSettings.LC_ALL = cfg.locale;
    };
  };
}
