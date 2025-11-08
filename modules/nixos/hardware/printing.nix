{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.printing;

  vendorDrivers = with pkgs; {
    canon = [ cnijfilter2 ];
    hp = [ hplipWithPlugin ];
    samsung = [ samsung-unified-linux-driver ];
  };
in
{
  options.modules.nixos.printing = {
    enable = lib.mkEnableOption "Enable printing support";

    vendor = lib.mkOption {
      type = lib.types.enum [
        "canon"
        "hp"
        "samsung"
      ];
      default = "canon";
      description = "Printer vendor";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          enable = true;
          userServices = true;
        };
      };

      printing = {
        enable = true;
        drivers = vendorDrivers.${cfg.vendor};
      };
    };
  };
}
