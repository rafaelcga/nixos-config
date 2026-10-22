{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.containers;

  withBackup =
    let
      usesBackup = _: containerConfig: containerConfig.enable && containerConfig.enableBackup;
    in
    lib.filterAttrs usesBackup cfg.services;

  withoutBackup =
    let
      isExcluded = _: containerConfig: !containerConfig.enable || !containerConfig.enableBackup;
    in
    lib.filterAttrs isExcluded cfg.services;

  perContainerExcludes = lib.concatLists (
    lib.mapAttrsToList (
      name: containerConfig:
      map (path: "/${name}/${lib.removePrefix "/" path}") containerConfig.excludeFromBackup
    ) withBackup
  );

  withoutBackupExcludes = lib.mapAttrsToList (name: _: "/${name}/**") withoutBackup;

  excludesFile =
    let
      allExcludes = cfg.backup.extraExcludes ++ perContainerExcludes ++ withoutBackupExcludes;
    in
    pkgs.writeText "rclone-container-excludes" (lib.concatStringsSep "\n" allExcludes + "\n");
in
{
  options.modules.nixos.containers.backup = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable rclone automatic backup of containers' data";
    };

    remotePath = lib.mkOption {
      type = lib.types.str;
      default = "proton:backups/containers";
      description = "Destination rclone remote and path";
    };

    extraExcludes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional paths relative to dataDir to exclude from the backup";
    };
  };

  config = lib.mkIf (cfg.backup.enable && withBackup != { }) {
    sops.secrets."rclone_proton_config" = { };

    systemd.services.rclone-containers-backup = {
      description = "Backup ${cfg.dataDir} to Proton Drive";
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "sops-nix.service"
      ];
      restartIfChanged = false;
      stopIfChanged = false;
      serviceConfig =
        let
          stateDir = "rclone-proton";
          mutableConfig = "/var/lib/${stateDir}/rclone.conf";
        in
        {
          Type = "oneshot";
          StateDirectory = stateDir;
          StateDirectoryMode = "0700";
          ExecStart = lib.getExe (
            pkgs.writeShellApplication {
              name = "rclone-containers-backup";
              runtimeInputs = with pkgs; [
                coreutils
                rclone
              ];
              text = ''
                # rclone requires a mutable configuration
                if [ ! -f "${mutableConfig}" ]; then
                  echo "Seeding initial rclone.conf from sops-nix..."
                  install -m 600 "${config.sops.secrets."rclone_proton_config".path}" "${mutableConfig}"
                fi

                echo "Starting rclone sync of ${cfg.dataDir} to ${cfg.backup.remotePath}..."
                rclone sync "${cfg.dataDir}" "${cfg.backup.remotePath}" \
                  --config "${mutableConfig}" \
                  --exclude-from "${excludesFile}" \
                  --protondrive-replace-existing-draft=true \
                  --transfers 4 \
                  --checkers 8 \
                  --fast-list \
                  --stats-one-line \
                  -v
              '';
            }
          );
        };
    };

    systemd.timers.rclone-containers-backup = {
      description = "Periodic backup timer for NixOS containers";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "30m";
        Persistent = true;
      };
    };
  };
}
