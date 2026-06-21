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
      initrd = {
        systemd.enable = true;
        verbose = true;
      };

      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
        systemd-boot = {
          enable = true;
          editor = false;
          inherit (cfg) configurationLimit;
          edk2-uefi-shell.enable = true;

          # Overwrite new generation with `default @saved` but boot into it after
          # a nixos-rebuild
          extraInstallCommands = ''
            NIXOS_GENERATION=$(grep "^default " /boot/loader/loader.conf | awk '{print $2}')
            sed -i 's|^default .*|default @saved|' /boot/loader/loader.conf
            if [[ -n "$NIXOS_GENERATION" ]] && [[ "$NIXOS_GENERATION" != "@saved" ]]; then
              ${pkgs.systemd}/bin/bootctl set-oneshot "$NIXOS_GENERATION" || true
            fi
          '';
        };
      };

      tmp = {
        useTmpfs = true; # /tmp on RAM
        cleanOnBoot = true;
      };
    };

    security.rtkit.enable = true; # enable RealtimeKit (RTKit)

    services.fwupd.enable = true; # firmware updates

    # github:CachyOS/CachyOS-Settings/blob/master/usr/lib/systemd/zram-generator.conf
    zramSwap = {
      enable = true;
      memoryPercent = 100; # amount of ZRAM == system RAM
      priority = 100;
      algorithm = "zstd";
    };
  };
}
