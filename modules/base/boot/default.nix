{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.base.boot;

  kernelMap = {
    lts = pkgs.linuxPackages;
    latest = pkgs.linuxPackages_latest;
  };
in
{
  options.base.boot = {
    enable = lib.mkEnableOption "base boot configuration";

    loader = lib.mkOption {
      type = lib.types.enum [ "systemd-boot" "limine" ];
      default = "systemd-boot";
      description = ''
        Which bootloader to use. Supported values:
        - "systemd-boot"
        - "limine"
      '';
    };

    kernel = lib.mkOption {
      type = lib.types.enum [ "lts" "latest" ];
      default = "lts";
      description = ''
        Which Linux kernel to use. Supported values:
        - "lts"
        - "latest"
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelPackages = kernelMap.${cfg.kernel};
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
