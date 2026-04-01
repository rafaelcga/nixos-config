{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.unmanic;
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

    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "Port number";
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
      allowedTCPPorts = [ cfg.port ];
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

        ExecStart = "${lib.getExe cfg.package} --port ${toString cfg.port}";
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
        ProcSubset = "pid";
        ProtectControlGroups = !config.boot.isContainer;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelLogs = !config.boot.isContainer;
        ProtectKernelModules = !config.boot.isContainer;
        ProtectKernelTunables = !config.boot.isContainer;
        ProtectProc = "invisible";
        ProtectSystem = true;
        LockPersonality = true;
        PrivateTmp = !config.boot.isContainer;
        PrivateUsers = true;
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
