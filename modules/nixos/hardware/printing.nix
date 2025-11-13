{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) user;
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
in
{
  options.modules.nixos.printing = {
    enable = lib.mkEnableOption "Enable printing support";

    vendor = lib.mkOption {
      type = lib.types.enum [
        "brother"
        "canon"
        "hp"
      ];
      default = "brother";
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

      udev.packages = with pkgs; [ sane-airscan ];
    };

    hardware.sane = {
      enable = true;
      extraBackends = with pkgs; [ sane-airscan ];
      disabledDefaultBackends = [ "escl" ];
    };

    users.users.${user.name}.extraGroups = [
      "scanner"
      "lp"
    ];
  };
}
