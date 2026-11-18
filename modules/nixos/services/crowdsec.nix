{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.crowdsec;
  cfgCrowdsec = config.services.crowdsec;
  cfgBouncer = config.services.crowdsec-firewall-bouncer;

  config_paths = cfgCrowdsec.settings.config.config_paths;

  # Adapted from the `crowdsec-firewall-bouncer-register` service in
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/security/crowdsec-firewall-bouncer.nix
  mkRegisterService =
    _:
    {
      bouncerName,
      apiKeyFile,
      serviceName,
      ...
    }:
    let
      name = lib.escapeShellArg bouncerName;
    in
    lib.nameValuePair serviceName rec {
      description = "Register ${bouncerName} to the local CrowdSec service";
      wantedBy = [ "multi-user.target" ];
      after = [ "crowdsec.service" ];
      wants = after;
      path = [ cfgCrowdsec.package ];
      script = ''
        echo "Checking bouncer registration..."
        if cscli bouncers list --output json | ${lib.getExe pkgs.jq} -e -- ${lib.escapeShellArg "any(.[]; .name == \"${bouncerName}\")"} >/dev/null; then
          echo "Bouncer already registered. Verify the API key is still present"
          if [ -s ${apiKeyFile} ]; then
            echo "API key file exists, nothing to do"
            exit 0
          fi
          echo "Bouncer registered but API key is not present. Unregistering bouncer..."
          cscli bouncers delete -- ${name} || true
        else
          echo "Bouncer not registered. Removing any previously saved API key"
          rm -f ${apiKeyFile}
        fi

        echo "Registering the bouncer and saving the new API key"
        # Only stdout goes to the key file: warnings printed by cscli on stderr
        # would otherwise end up in the key and break its consumers
        if ! cscli bouncers add --output raw -- ${name} >${apiKeyFile}; then
          echo "Failed to register the bouncer" >&2
          rm -f ${apiKeyFile}
          exit 1
        fi

        chmod 0440 ${apiKeyFile}
        echo "Successfully registered bouncer and saved API key"
      '';
      serviceConfig = {
        Type = "oneshot";

        # Run as crowdsec user to be able to use cscli
        User = cfgCrowdsec.user;
        Group = cfgCrowdsec.group;

        StateDirectory = serviceName;
        ReadWritePaths = [ "/var/lib/crowdsec" ];

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

  # The upstream module only hooks the blocklists into the `input` chain when
  # using nftables. Also drop banned IPs on forwarded (container) traffic.
  mkForwardChain =
    family: setName: nftCfg:
    lib.mkIf (cfgBouncer.createRulesets && nftCfg.enabled && nftCfg.set-only) {
      ${nftCfg.table}.content = ''
        chain ${nftCfg.chain}-forward {
          type filter hook forward priority filter; policy accept;
          ${family} saddr @${setName} drop
        }
      '';
    };
in
{
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
                type = lib.types.nonEmptyStr;
                default = "crowdsec-${name}-bouncer";
                description = "Name to register the bouncer as to the CrowdSec API";
              };

              serviceName = lib.mkOption {
                type = lib.types.str;
                default = "${config.bouncerName}-register";
                readOnly = true;
                description = "Name of the service generating the API key";
              };

              apiKeyFile = lib.mkOption {
                type = lib.types.str;
                default = "/var/lib/${config.serviceName}/api-key.cred";
                readOnly = true;
                description = "Path to the API key generated when registering the bouncer";
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
          config.api.server = {
            listen_uri = "127.0.0.1:${cfg.lapiPort}";
            online_client.credentials_path = "${config_paths.data_dir}/online_api_credentials.yaml";
          };

          console.enrollKeyFile = config.sops.secrets."crowdsec/enroll_key".path;

          acquisitions = [
            {
              # Matches on the same field are OR-ed by journalctl, so a single
              # reader covers all transports. Each entry is read exactly once:
              # overlapping acquisitions would duplicate events and make
              # scenarios trigger with half the intended threshold.
              source = "journalctl";
              journalctl_filter = [
                "_TRANSPORT=journal"
                "_TRANSPORT=syslog"
                "_TRANSPORT=kernel"
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
      };

      # Registration, logging and the nftables rulesets are handled upstream
      crowdsec-firewall-bouncer.enable = true;
    };

    networking.nftables.tables = lib.mkIf (cfgBouncer.settings.mode == "nftables") (
      lib.mkMerge [
        (mkForwardChain "ip" "crowdsec-blacklists" cfgBouncer.settings.nftables.ipv4)
        (mkForwardChain "ip6" "crowdsec6-blacklists" cfgBouncer.settings.nftables.ipv6)
      ]
    );

    sops.secrets."crowdsec/enroll_key" = { };

    systemd.services = lib.mapAttrs' mkRegisterService (
      lib.filterAttrs (_: bouncer: bouncer.enable) cfg.bouncers
    );
  };
}
