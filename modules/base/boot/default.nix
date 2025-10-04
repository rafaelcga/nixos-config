{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.base.boot;
in
{
  options.base.boot = {
    enable = lib.mkEnableOption "base boot configuration";

    loader = lib.mkOption {
      type = lib.types.enum [
        "systemd-boot"
        "limine"
      ];
      default = "systemd-boot";
      description = ''
        Which bootloader to use. Supported values:
        - "systemd-boot"
        - "limine"
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      initrd = {
        systemd.enable = true;
        verbose = true;
      };
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = lib.mkIf (cfg.loader == "systemd-boot") {
          enable = true;
          editor = false;
        };
        limine = lib.mkIf (cfg.loader == "limine") {
          enable = true;
          enableEditor = false;
        };
      };
      # /tmp on RAM
      tmp = {
        useTmpfs = true;
        cleanOnBoot = true;
      };
    };
  };
}
