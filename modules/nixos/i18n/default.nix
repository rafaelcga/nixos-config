{ config, lib, ... }:
let
  cfg = config.modules.nixos.i18n;
in
{
  options.modules.nixos.i18n = {
    enable = lib.mkEnableOption "localization configuration";
    locale = lib.mkOption {
      default = "en_IE.UTF-8/UTF-8"; # Irish English (for international locale)
      type = lib.types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    i18n = {
      defaultLocale = cfg.locale;
      extraLocaleSettings = {
        LC_ADDRESS = cfg.locale;
        LC_IDENTIFICATION = cfg.locale;
        LC_MEASUREMENT = cfg.locale;
        LC_MONETARY = cfg.locale;
        LC_NAME = cfg.locale;
        LC_NUMERIC = cfg.locale;
        LC_PAPER = cfg.locale;
        LC_TELEPHONE = cfg.locale;
        LC_TIME = cfg.locale;
      };
    };
  };
}
