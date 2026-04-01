{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.unmanic;

  settingsOpts = {
    options = {
      ui_port = lib.mkOption {
        type = lib.types.port;
        default = 8888;
        description = "The port Unmanic listens on.";
      };

      ui_address = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "The IP address Unmanic binds to.";
      };

      ssl_enabled = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable SSL/TLS for the web interface.";
      };

      ssl_certfilepath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the SSL certificate file.";
      };

      ssl_keyfilepath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the SSL key file.";
      };

      config_path = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.dataDir}/.unmanic/config";
        description = "Path to the configuration directory.";
      };

      log_path = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.dataDir}/.unmanic/logs";
        description = "Path to the logs directory.";
      };

      plugins_path = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.dataDir}/.unmanic/plugins";
        description = "Path to the plugins directory.";
      };

      userdata_path = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.dataDir}/.unmanic/userdata";
        description = "Path to the userdata directory.";
      };

      debugging = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable extensive debug logging.";
      };

      log_buffer_retention = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Configure log buffer retention (in days).";
      };

      first_run = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Tracks if this is the first time Unmanic has run.";
      };

      release_notes_viewed = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Tracks which release notes version the user has viewed.";
      };

      trial_welcome_viewed = lib.mkOption {
        type = lib.types.nullOr lib.types.bool; # Or str depending on how Unmanic tracks this
        default = null;
        description = "Tracks if the trial welcome message was viewed.";
      };

      library_path = lib.mkOption {
        type = lib.types.str;
        default = "/library";
        description = "The main library path to monitor/scan.";
      };

      enable_library_scanner = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable automated library scanning.";
      };

      schedule_full_scan_minutes = lib.mkOption {
        type = lib.types.int;
        default = 1440;
        description = "Minutes between scheduled full library scans.";
      };

      follow_symlinks = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Follow symlinks when scanning the library.";
      };

      concurrent_file_testers = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "Number of concurrent file tests to run.";
      };

      run_full_scan_on_start = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run a full library scan when Unmanic starts.";
      };

      clear_pending_tasks_on_restart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Clear the pending tasks queue upon service restart.";
      };

      auto_manage_completed_tasks = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Automatically clean up completed tasks.";
      };

      compress_completed_tasks_logs = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Compress logs for completed tasks.";
      };

      max_age_of_completed_tasks = lib.mkOption {
        type = lib.types.int;
        default = 91;
        description = "Maximum age (in days) to retain completed task history.";
      };

      always_keep_failed_tasks = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Always retain history of failed tasks regardless of age.";
      };

      cache_path = lib.mkOption {
        type = lib.types.str;
        default = "/tmp/unmanic";
        description = "Directory for Unmanic to store temporary video files during processing.";
      };

      installation_name = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Name for this specific Unmanic installation.";
      };

      installation_public_address = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Publicly accessible address for this installation.";
      };

      remote_installations = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "List of remote Unmanic nodes to connect to.";
      };

      distributed_worker_count_target = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Target count for distributed workers.";
      };

      number_of_workers = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Legacy: Number of local workers.";
      };

      worker_event_schedules = lib.mkOption {
        type = lib.types.nullOr lib.types.attrs;
        default = null;
        description = "Legacy: Schedules for worker events.";
      };
    };
  };
in
{
  options.modules.nixos.unmanic = {
    enable = lib.mkEnableOption "Enable Unmanic package and service";

    package = lib.mkPackageOption pkgs.local "unmanic" { };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/unmanic";
      description = ''
        The directory where Unmanic stores its configuration and state.
        This replaces the traditional /opt/unmanic path
      '';
    };

    settings = lib.mkOption {
      type = lib.types.submodule settingsOpts;
      default = { };
      description = "Unmanic settings; overwrites the ones set through the WebUI";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open ports in the firewall for the webinterface
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "unmanic";
      description = "User account under which Unmanic runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "unmanic";
      description = "Group under which Unmanic runs";
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users = lib.mkIf (cfg.user == "unmanic") {
        unmanic = {
          isSystemUser = true;
          group = cfg.group;
          home = cfg.dataDir;
          description = "Unmanic service user";
        };
      };

      groups = lib.mkIf (cfg.group == "unmanic") {
        unmanic = { };
      };
    };

    environment.systemPackages = [ cfg.package ];

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.settings.ui_port ];
    };

    systemd.services.unmanic = rec {
      description = "Unmanic - Library Optimiser";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = wants;

      environment = {
        HOME_DIR = cfg.dataDir;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        SupplementaryGroups = [
          "video"
          "render"
        ];

        ExecStartPre =
          let
            nonNullSettings = lib.filterAttrs (name: value: value != null) cfg.settings;
            nixSettingsJson = pkgs.writeText "unmanic-nix-settings.json" (builtins.toJSON nonNullSettings);
            unmanicJsonPath = "${cfg.settings.config_path}/settings.json";
          in
          lib.getExe (
            pkgs.writeShellApplication {
              name = "setup-unmanic-settings";
              runtimeInputs = with pkgs; [
                coreutils
                jq
              ];
              text = ''
                set -euo pipefail

                mkdir -p "${cfg.settings.config_path}"

                echo "Evaluating Unmanic settings"
                if [[ ! -f "${unmanicJsonPath}" ]]; then
                    echo "No existing settings.json found. Creating a new one..."
                    cp "${nixSettingsJson}" "${unmanicJsonPath}"
                    chmod 644 "${unmanicJsonPath}"
                else
                    echo "Existing settings.json found. Merging Nix settings..."
                    if jq -s '.[0] * .[1]' "${unmanicJsonPath}" "${nixSettingsJson}" > "${unmanicJsonPath}.tmp"; then
                        mv "${unmanicJsonPath}.tmp" "${unmanicJsonPath}"
                        chmod 644 "${unmanicJsonPath}"
                        echo "Merge successful."
                    else
                        echo "Failed to merge JSON files. The existing settings.json might be corrupted."
                        exit 1
                    fi
                fi
              '';
            }
          );

        ExecStart = "${lib.getExe cfg.package}";
        Restart = "always";
        RestartSec = 30;

        WorkingDirectory = cfg.dataDir;
        StateDirectory = lib.mkIf (cfg.dataDir == "/var/lib/unmanic") "unmanic";

        # Security options:
        CapabilityBoundingSet = [ "" ];
        NoNewPrivileges = true;
        SystemCallArchitectures = "native";
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = !config.boot.isContainer;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        ProtectControlGroups = !config.boot.isContainer;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelLogs = !config.boot.isContainer;
        ProtectKernelModules = !config.boot.isContainer;
        ProtectKernelTunables = !config.boot.isContainer;
        ProtectSystem = true;
        LockPersonality = true;
        PrivateTmp = !config.boot.isContainer;
        RemoveIPC = true;
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        SystemCallErrorNumber = "EPERM";
      };
    };
  };
}
