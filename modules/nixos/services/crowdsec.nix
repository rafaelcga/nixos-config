{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.crowdsec;
  usesCaddy = config.modules.nixos.caddy.enable;

  collections = [
    "crowdsecurity/linux"
    "crowdsecurity/linux-lpe"
    "crowdsecurity/http-cve"
    "crowdsecurity/base-http-scenarios"
    "crowdsecurity/sshd"
    "crowdsecurity/sshd-impossible-travel"
    "crowdsecurity/appsec-virtual-patching"
    "crowdsecurity/appsec-generic-rules"
    "crowdsecurity/appsec-crs"
  ]
  ++ lib.optionals usesCaddy [ "crowdsecurity/caddy" ];

  acquisitions = [
    {
      source = "file";
      filenames = [
        "/var/log/auth.log"
        "/var/log/syslog"
      ];
      labels = {
        type = "syslog";
      };
    }
    # crowdsecurity/linux-lpe
    {
      source = "journalctl";
      journalctl_filter = [
        "-k"
      ];
      labels = {
        type = "syslog";
      };
    }
    {
      source = "appsec";
      listen_addr = "127.0.0.1:${cfg.appsecPort}";
      appsec_configs = [ "crowdsecurity/appsec-default" ];
      labels = {
        type = "appsec";
      };
    }
  ]
  ++ lib.optionals usesCaddy [
    {
      source = "file";
      filenames = [ "${config.services.caddy.logDir}/*.log" ];
      labels = {
        type = "caddy";
      };
    }
  ];

  # https://github.com/crowdsecurity/crowdsec/blob/master/docker/docker_start.sh
  mkBouncer =
    name:
    let
      name = lib.toLower name;
    in
    {
      sops.secrets."crowdsec/${name}_bouncer_key" = { };
      sops.templates."crowdsec/${name}-env".content = ''
        BOUNCER_KEY=${config.sops.placeholder."crowdsec/${name}_bouncer_key"}
      '';

      systemd.services = {
        "register_crowdsec_${name}_bouncer" = {
          description = "Registers idempotently ${name} CrowdSec bouncer";
          after = [ "crowdsec.service" ];
          wants = [ "crowdsec.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = config.sops.templates."crowdsec/${name}-env".path;
          };
          script = ''
            set -euo pipefail

            if ! ${pkgs.crowdsec}/bin/cscli bouncers list -o json |
                ${pkgs.jq}/bin/jq -r ".[].name" |
                ${pkgs.coreutils}/bin/tr "[:upper:]" "[:lower:]" |
                ${pkgs.gnugrep}/bin/grep -q '^${name}$'; then
                ${pkgs.crowdsec}/bin/cscli bouncers add "${name}" -k "$BOUNCER_KEY"
            fi
          '';
        };
      };
    };

  bouncerConfigList = map mkBouncer cfg.bouncers;
in
{
  options.modules.nixos.crowdsec = {
    enable = lib.mkEnableOption "CrowdSec configuration";

    lapiPort = lib.mkOption {
      default = 8080;
      type = lib.types.ints.unsigned;
      description = "Port in localhost (127.0.0.1) for CrowdSec's LAPI";
    };

    appsecPort = lib.mkOption {
      default = 7422;
      type = lib.types.ints.unsigned;
      description = "Port in localhost (127.0.0.1) for AppSec";
    };

    bouncers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Names of bouncers to add to CrowdSec. Their API keys must be configured
        in the repository secrets.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.crowdsec = {
          enable = true;
          autoUpdateService = true;

          settings.general = {
            api.server.listen_uri = "127.0.0.1:${cfg.lapiPort}";
          };
          hub.collections = collections;
          localConfig.acquisitions = acquisitions;
        };

        environment.systemPackages = [ pkgs.crowdsec-firewall-bouncer ];

        sops.secrets."crowdsec/enroll_key" = { };
        sops.templates."crowdsec/console-enroll-env".content = ''
          ENROLL_KEY=${config.sops.placeholder."crowdsec/enroll_key"}
        '';

        systemd.services."enroll_crowdsec_console" = {
          description = "Enrolls the engine at app.crowdsec.net";
          after = [ "crowdsec.service" ];
          wants = [ "crowdsec.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = config.sops.templates."crowdsec/console-enroll-env".path;
          };
          script = ''
            set -euo pipefail

            ${pkgs.crowdsec}/bin/cscli console enroll "$ENROLL_KEY"
          '';
        };
      }
    ]
    ++ bouncerConfigList
  );
}
