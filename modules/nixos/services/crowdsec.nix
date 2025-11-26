{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.crowdsec;

  rootDir = "/var/lib/crowdsec";
  confDir = "/etc/crowdsec";
  logDir = "/var/log/crowdsec";

  lapiFile = "${rootDir}/lapi_credentials.yaml";
  capiFile = "${rootDir}/capi_credentials.yaml";

  bouncerOpts =
    { name, config, ... }:
    {
      options = {
        enable = lib.mkEnableOption "Enable bouncer";

        bouncerName = lib.mkOption {
          type = lib.types.str;
          default = "crowdsec-${name}-bouncer";
          description = "Name to register the bouncer as to the CrowdSec API";
        };

        apiKeyFile = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/crowdsec-${name}-bouncer-register/api-key.cred";
          description = "Path to the API key generated to register bouncer";
        };

        serviceName = lib.mkOption {
          type = lib.types.str;
          default = "${config.bouncerName}-register";
          readOnly = true;
          internal = true;
          description = "Name of the service generating the API key";
        };
      };
    };

  # See https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/security/crowdsec-firewall-bouncer.nix
  registerBouncer =
    name: bouncerConfig:
    let
      inherit (bouncerConfig)
        enable
        bouncerName
        apiKeyFile
        serviceName
        ;
    in
    {
      "${serviceName}" = lib.mkIf enable {
        description = "Register the CrowdSec Bouncer to the local CrowdSec service";
        wantedBy = [ "multi-user.target" ];
        after = [ "crowdsec.service" ];
        wants = [ "crowdsec.service" ];

        serviceConfig = {
          Type = "oneshot";
          User = config.services.crowdsec.user;
          Group = config.services.crowdsec.group;
          StateDirectory = serviceName;
          # Needs write permissions to add the bouncer
          ReadWritePaths = [ rootDir ];
          DynamicUser = true;
          LockPersonality = true;
          PrivateDevices = true;
          ProcSubset = "pid";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          RestrictNamespaces = true;
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
          RestrictAddressFamilies = "none";
          CapabilityBoundingSet = [ "" ];
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
            "~@resources"
          ];
          UMask = "0077";
        };

        script =
          let
            jq = lib.getExe pkgs.jq;
            cscli = "/run/current-system/sw/bin/cscli";
          in
          ''
            set -euo pipefail

            if ${cscli} bouncers list --output json \
              | ${jq} -e -- ${lib.escapeShellArg "any(.[]; .name == \"${bouncerName}\")"} >/dev/null; then
              # Bouncer already registered. Verify the API key is still present
              if [[ ! -f ${apiKeyFile} ]]; then
                echo "Bouncer registered but API key is not present"
                exit 1
              fi
            else
              # Bouncer not registered
              # Remove any previously saved API key
              rm -f "${apiKeyFile}"
              # Register the bouncer and save the new API key
              if ! ${cscli} bouncers add --output raw \
                -- ${lib.escapeShellArg bouncerName} >${apiKeyFile}; then
                # Failed to register the bouncer
                rm -f "${apiKeyFile}"
                exit 1
              fi
            fi
          '';
      };
    };
in
{
  options.modules.nixos.crowdsec = {
    enable = lib.mkEnableOption "Enable CrowdSec";

    lapiPort = lib.mkOption {
      default = 8080;
      type = lib.types.port;
      apply = builtins.toString;
      description = "Port in localhost (127.0.0.1) for CrowdSec's LAPI";
    };

    appsecPort = lib.mkOption {
      default = 7422;
      type = lib.types.port;
      apply = builtins.toString;
      description = "Port in localhost (127.0.0.1) for AppSec";
    };

    bouncers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule bouncerOpts);
      default = { };
      description = "Bouncers to register in the CrowdSec API";
    };
  };

  config = lib.mkIf cfg.enable {
    # See https://github.com/nixos/nixpkgs/issues/446764
    systemd.tmpfiles.settings =
      let
        inherit (config.services.crowdsec) user group;
      in
      {
        "10-crowdsec" = {
          "${rootDir}".d = {
            inherit user group;
            mode = "0755";
          };
          "${logDir}".d = {
            inherit user group;
            mode = "0755";
          };
          "${capiFile}".f = {
            inherit user group;
            mode = "0750";
          };
        };
      };

    services = {
      crowdsec = {
        enable = true;
        autoUpdateService = true;

        settings = {
          general.api.server = {
            enable = true;
            listen_uri = "127.0.0.1:${cfg.lapiPort}";
          };

          # See https://github.com/NixOS/nixpkgs/issues/445342
          lapi.credentialsFile = lapiFile;
          capi.credentialsFile = capiFile;

          console = {
            # See https://github.com/NixOS/nixpkgs/issues/445342
            # tokenFile = config.sops.secrets."crowdsec/enroll_key".path;
            configuration = {
              share_custom = true;
              share_manual_decisions = true;
              share_tainted = true;
              share_context = true;
              console_management = true;
            };
          };
        };

        hub.collections = [
          "crowdsecurity/linux"
          "crowdsecurity/linux-lpe"
          "crowdsecurity/http-cve"
          "crowdsecurity/base-http-scenarios"
          "crowdsecurity/sshd"
          "crowdsecurity/sshd-impossible-travel"
          "crowdsecurity/appsec-virtual-patching"
          "crowdsecurity/appsec-generic-rules"
          "crowdsecurity/appsec-crs"
        ];

        localConfig.acquisitions =
          # crowdsecurity/linux-lpe
          (
            let
              acquisTemplate = filter: {
                source = "journalctl";
                journalctl_filter = [ "_TRANSPORT=${filter}" ];
                labels.type = "syslog";
              };
            in
            lib.map acquisTemplate [
              "journal"
              "syslog"
              "stdout"
              "kernel"
            ]
          )
          ++ [
            {
              source = "journalctl";
              journalctl_filter = [
                "--facility=auth"
                "--facility=authpriv"
              ];
              labels.type = "syslog";
            }
            {
              source = "appsec";
              listen_addr = "127.0.0.1:${cfg.appsecPort}";
              appsec_configs = [ "crowdsecurity/appsec-default" ];
              labels.type = "appsec";
            }
          ];
      };

      crowdsec-firewall-bouncer = {
        enable = true;
        settings = {
          log_mode = "file";
          log_dir = logDir;
          log_compression = true;
          log_max_size = 100;
          log_max_backups = 3;
          log_max_age = 30;
          deny_log = true;
          iptables_chains = [
            "INPUT"
            "FORWARD"
          ];
        };
      };
    };

    sops.secrets = {
      "crowdsec/enroll_key" = {
        owner = config.services.crowdsec.user;
        group = config.services.crowdsec.group;
      };
    };

    systemd.services = lib.mkMerge (
      [
        {
          "enroll-crowdsec-console" = rec {
            wantedBy = [ "multi-user.target" ];
            after = [ "crowdsec.service" ];
            wants = after;
            serviceConfig = {
              Type = "oneshot";
              User = config.services.crowdsec.user;
              Group = config.services.crowdsec.group;
              ReadWritePaths = [
                rootDir
                confDir
              ];
              UMask = "0077";
            };
            script =
              let
                cscli = "/run/current-system/sw/bin/cscli";
              in
              ''
                ${cscli} console enroll "$(cat ${
                  config.sops.secrets."crowdsec/enroll_key".path
                })" --name ${config.services.crowdsec.name}
              '';
          };

          crowdsec-firewall-bouncer = rec {
            after = [ "crowdsec-firewall-bouncer-register.service" ];
            wants = after;
            serviceConfig = {
              DynamicUser = lib.mkForce false;
              User = config.services.crowdsec.user;
              Group = config.services.crowdsec.group;
            };
          };
        }
      ]
      ++ lib.mapAttrsToList registerBouncer cfg.bouncers
    );
  };
}
