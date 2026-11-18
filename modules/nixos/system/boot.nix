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
          # Runs inside a systemd-run transient unit (nh >= 4.5) with a minimal
          # PATH, so every external tool must be referenced by store path.
          extraInstallCommands =
            let
              sed = lib.getExe pkgs.gnused;
              bootctl = "${config.systemd.package}/bin/bootctl";
            in
            ''
              loader_conf=${lib.escapeShellArg "${config.boot.loader.efi.efiSysMountPoint}/loader/loader.conf"}
              generation=$(${sed} -n 's/^default[[:space:]]\+//p' "$loader_conf")
              if [[ -n $generation && $generation != @saved ]]; then
                ${sed} -i 's/^default[[:space:]].*/default @saved/' "$loader_conf"
                ${bootctl} set-oneshot "$generation" || true
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
