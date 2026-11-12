{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.containers;

  split = lib.partition (name: cfg.services.${name}.enable && cfg.services.${name}.enableBackup) (
    lib.attrNames cfg.services
  );
  backedUp = split.right;
  notBackedUp = split.wrong;

  excludesFile =
    let
      perContainerExcludes = lib.concatMap (
        name: map (path: "/${name}/${lib.removePrefix "/" path}") cfg.services.${name}.excludeFromBackup
      ) backedUp;
      allExcludes = [
        ".container-home/**" # .local and .cache of OCI containers
      ]
      ++ cfg.backup.extraExcludes
      ++ perContainerExcludes
      ++ map (name: "/${name}/**") notBackedUp;
    in
    pkgs.writeText "rclone-container-excludes" (lib.concatStringsSep "\n" allExcludes + "\n");

  # Containers stopped during the sync so their databases are copied consistently.
  # Only those with a dataDir: stopping e.g. proton-vpn would take down every
  # container bound to it.
  unitsToStop =
    map
      (
        name:
        if cfg.services.${name}.engine == "oci" then
          "podman-${name}.service"
        else
          "container@${name}.service"
      )
      (
        lib.filter (
          name: cfg.services.${name}.dataDir != null && cfg.services.${name}.stopDuringBackup
        ) backedUp
      );
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

  config = lib.mkIf (cfg.backup.enable && backedUp != [ ]) {
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
              runtimeInputs = [
                pkgs.coreutils
                pkgs.rclone
                config.systemd.package
              ];
              text = ''
                # rclone requires a mutable configuration
                if [ ! -f "${mutableConfig}" ]; then
                  echo "Seeding initial rclone.conf from sops-nix..."
                  install -m 600 "${config.sops.secrets."rclone_proton_config".path}" "${mutableConfig}"
                fi

                # Stop running containers for a consistent copy; restart them even if the sync fails
                stopped=()
                for unit in ${lib.escapeShellArgs unitsToStop}; do
                  if systemctl is-active --quiet "$unit"; then
                    stopped+=("$unit")
                  fi
                done
                if ((''${#stopped[@]})); then
                  trap 'echo "Restarting ''${stopped[*]}"; systemctl start "''${stopped[@]}"' EXIT
                  echo "Stopping ''${stopped[*]} for the backup..."
                  systemctl stop "''${stopped[@]}"
                fi

                echo "Starting rclone sync of ${cfg.dataDir} to ${cfg.backup.remotePath}..."
                rclone sync "${cfg.dataDir}" "${cfg.backup.remotePath}" \
                  --config "${mutableConfig}" \
                  --exclude-from "${excludesFile}" \
                  --delete-excluded \
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
        # Night-time, since containers are briefly offline while syncing
        OnCalendar = "*-*-* 04:00:00";
        RandomizedDelaySec = "30m";
        Persistent = true;
      };
    };
  };
}
