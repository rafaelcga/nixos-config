{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.printing;

  vendorDrivers = with pkgs; {
    brother = [
      brgenml1lpr
      brgenml1cupswrapper
    ];
    canon = [
      cnijfilter2
    ];
    hp = [
      hplipWithPlugin
    ];
  };
  extraDrivers = lib.concatMap (vendor: vendorDrivers.${vendor}) cfg.vendors;
in
{
  options.modules.nixos.printing = {
    enable = lib.mkEnableOption "Enable printing and scanning support";

    vendors = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (
        lib.types.enum [
          "brother"
          "canon"
          "hp"
        ]
      );
      description = "List of one or more printer vendors";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      printing = {
        enable = true;
        drivers = extraDrivers;
      };

      udev.packages = with pkgs; [ sane-airscan ];
    };

    hardware.sane = {
      enable = true;
      extraBackends = with pkgs; [ sane-airscan ];
      disabledDefaultBackends = [ "escl" ];
    };

    users.users.${userName}.extraGroups = [
      "scanner"
      "lp"
    ];
  };
}
