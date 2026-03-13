{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.crowdsec;
  cfgCrowdsec = config.services.crowdsec;

  config_paths = cfgCrowdsec.settings.config.config_paths;

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
      "${serviceName}" = lib.mkIf enable rec {
        description = "Register ${bouncerName} to the local CrowdSec service";
        wantedBy = [ "multi-user.target" ];
        after = [ "crowdsec.service" ];
        wants = after;
        path = [ config.services.crowdsec.configuredCscli ];

        script = ''
          # Ensure the directory exists
          mkdir -p "$(dirname ${apiKeyFile})" || true

          echo "Checking bouncer registration..."
          if cscli bouncers list --output json | ${lib.getExe pkgs.jq} -e -- ${lib.escapeShellArg "any(.[]; .name == \"${bouncerName}\")"} >/dev/null; then

            echo "Bouncer already registered. Verify the API key is still present"
            if [ ! -f ${apiKeyFile} ]; then
              echo "Bouncer registered but API key is not present"
              echo "Unregistering bouncer..."
              cscli bouncers delete ${bouncerName} || true
            else
              echo "API key file exists, nothing to do"
              exit 0
            fi
          else
            echo "Bouncer not registered"
            echo "Remove any previously saved API key"
            rm -f '${apiKeyFile}'
          fi

          echo "Register the bouncer and save the new API key"
          if ! cscli bouncers add --output raw -- ${lib.escapeShellArg bouncerName} > ${apiKeyFile} 2>&1; then
            echo "Failed to register the bouncer"
            cat ${apiKeyFile} || true  # Show error message
            rm -f ${apiKeyFile}
              exit 1
          fi

          chmod 0440 ${apiKeyFile} || true
          echo "Successfully registered bouncer and saved API key"

          cscli bouncers list
        '';
        serviceConfig = {
          Type = "oneshot";

          # Run as crowdsec user to be able to use cscli
          User = cfgCrowdsec.user;
          Group = cfgCrowdsec.group;

          StateDirectory = "${serviceName} crowdsec";
          StateDirectoryMode = "0750";

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
      };
    };
in
{
  disabledModules = [
    "services/security/crowdsec.nix"
    "services/security/crowdsec-firewall-bouncer.nix"
  ];

  imports = [
    ./crowdsec-pr.nix
    ./crowdsec-firewall-bouncer-pr.nix
  ];

  options.modules.nixos.crowdsec = {
    enable = lib.mkEnableOption "Enable CrowdSec";

    lapiPort = lib.mkOption {
      default = 8080;
      type = lib.types.port;
      apply = toString;
      description = "Port in localhost (127.0.0.1) for CrowdSec's LAPI";
    };

    appsecPort = lib.mkOption {
      default = 7422;
      type = lib.types.port;
      apply = toString;
      description = "Port in localhost (127.0.0.1) for AppSec";
    };

    bouncers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
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
          }
        )
      );
      default = { };
      description = "Bouncers to register in the CrowdSec API";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      crowdsec = {
        enable = true;
        autoUpdateService = true;
        openFirewall = true;
        package = pkgs.local.crowdsec;

        hub = {
          collections = [
            "crowdsecurity/linux"
            "crowdsecurity/linux-lpe"
            "crowdsecurity/http-cve"
            "crowdsecurity/base-http-scenarios"
            "crowdsecurity/sshd"
            "crowdsecurity/sshd-impossible-travel"
            "crowdsecurity/appsec-virtual-patching"
            "crowdsecurity/appsec-generic-rules"
          ];
          parsers = [
            "crowdsecurity/whitelists" # Avoid banning LAN
          ]
          ++ lib.optionals config.modules.nixos.containers.services.jellyfin.enable [
            "crowdsecurity/jellyfin-whitelist" # Avoid banning Jellyfin events
          ];
        };

        settings = {
          config = {
            api.server = {
              listen_uri = "127.0.0.1:${cfg.lapiPort}";
              online_client.credentials_path = "${config_paths.data_dir}/online_api_credentials.yaml";
            };
          };

          console.enrollKeyFile = config.sops.secrets."crowdsec/enroll_key".path;

          acquisitions =
            (
              let
                acquisTemplate = filterName: {
                  source = "journalctl";
                  journalctl_filter = [ "_TRANSPORT=${filterName}" ];
                  labels.type = "syslog";
                };
              in
              lib.map acquisTemplate [
                "journal"
                "syslog"
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
                appsec_configs = [
                  "crowdsecurity/appsec-default"
                  "crowdsecurity/crs"
                ];
                labels.type = "appsec";
              }
            ];
        };
      };

      crowdsec-firewall-bouncer = {
        enable = true;
        registerBouncer.enable = true;

        settings = {
          log_mode = "file";
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
        owner = cfgCrowdsec.user;
        group = cfgCrowdsec.group;
      };
    };

    systemd.services = lib.mkMerge (lib.mapAttrsToList registerBouncer cfg.bouncers);
  };
}
