{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.boot;
in
{
  options.modules.nixos.boot = {
    enable = lib.mkEnableOption "boot configuration";
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
      kernelPackages = pkgs.linuxPackages_zen;
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
