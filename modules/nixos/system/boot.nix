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
    configurationLimit = lib.mkOption {
      type = lib.types.int;
      default = 50;
      description = "Maximum number of latest generations in the boot menu.";
    };
  };

  config = {
    boot = {
      kernelPackages = pkgs.linuxPackages_zen;
      initrd = {
        systemd.enable = true;
        verbose = true;
      };

      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          enable = true;
          editor = false;
          inherit (cfg) configurationLimit;
          edk2-uefi-shell.enable = true;
        };
      };

      tmp = {
        useTmpfs = true; # /tmp on RAM
        cleanOnBoot = true;
      };
    };
  };
}
