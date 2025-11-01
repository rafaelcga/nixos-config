{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.crowdsec;

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
  ];

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
  ];

  sopsConfig =
    let
      enrollSopsConfig = {
        secrets."crowdsec/enroll_key" = { };
        templates."crowdsec/console-enroll-env".content = ''
          ENROLL_KEY=${config.sops.placeholder."crowdsec/enroll_key"}
        '';
      };
      mkBouncerSopsConfig = name: {
        secrets."crowdsec/${name}_bouncer_key" = { };
        templates."crowdsec/${name}-env".content = ''
          BOUNCER_KEY=${config.sops.placeholder."crowdsec/${name}_bouncer_key"}
        '';
      };
      bouncerSopsList = map mkBouncerSopsConfig cfg.bouncers;
    in
    {
      sops = lib.mkMerge ([ enrollSopsConfig ] ++ bouncerSopsList);
    };

  systemdConfig =
    let
      enrollService = {
        enroll-crowdsec-console = {
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
      };
      # https://github.com/crowdsecurity/crowdsec/blob/master/docker/docker_start.sh
      mkBouncerService = name: {
        "register-crowdsec-${name}-bouncer" = {
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

            if ! ${pkgs.crowdsec}/bin/cscli bouncers list -o json \
              | ${pkgs.jq}/bin/jq -r ".[].name" \
              | ${pkgs.coreutils}/bin/tr "[:upper:]" "[:lower:]" \
              | ${pkgs.gnugrep}/bin/grep -q '^${name}$'; then
              ${pkgs.crowdsec}/bin/cscli bouncers add "${name}" -k "$BOUNCER_KEY"
            fi
          '';
        };
      };
      bouncerServiceList = map mkBouncerService cfg.bouncers;
    in
    {
      systemd.services = lib.mkMerge ([ enrollService ] ++ bouncerServiceList);
    };
in
{
  options.modules.nixos.crowdsec = {
    enable = lib.mkEnableOption "Enable CrowdSec";

    lapiPort = lib.mkOption {
      default = 8080;
      type = lib.types.ints.unsigned;
      apply = builtins.toString;
      description = "Port in localhost (127.0.0.1) for CrowdSec's LAPI";
    };

    appsecPort = lib.mkOption {
      default = 7422;
      type = lib.types.ints.unsigned;
      apply = builtins.toString;
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
      }
      sopsConfig
      systemdConfig
    ]
  );
}
