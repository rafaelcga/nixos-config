{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.crowdsec;

  cscli = "${pkgs.crowdsec}/bin/cscli";
  grep = "${pkgs.gnugrep}/bin/grep";
  jq = "${pkgs.jq}/bin/jq";

  bouncerSopsList =
    let
      mkBouncerSopsConfig = name: {
        secrets."crowdsec/${name}_bouncer_key" = { };
        templates."crowdsec/${name}-env".content = ''
          BOUNCER_KEY=${config.sops.placeholder."crowdsec/${name}_bouncer_key"}
        '';
      };
    in
    map mkBouncerSopsConfig cfg.bouncers;

  bouncerServiceList =
    let # https://github.com/crowdsecurity/crowdsec/blob/master/docker/docker_start.sh
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

            if ! ${cscli} bouncers list -o json \
              | ${jq} -r ".[].name" \
              | ${grep} -qiP "^${name}$"; then
              ${cscli} bouncers add "${name}" -k "$BOUNCER_KEY"
            fi
          '';
        };
      };
    in
    map mkBouncerService cfg.bouncers;
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
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Names of bouncers to add to CrowdSec. Their API keys must be configured
        in the repository secrets.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # See https://github.com/nixos/nixpkgs/issues/446764
    systemd.tmpfiles.rules =
      let
        inherit (config.services.crowdsec) user group;
      in
      [
        "d /var/lib/crowdsec 0755 ${user} ${group} - -"
        # In contrast to the `lapi.credentialsFile`, the `capi.credentialsFile` must already exist beforehand
        "f /var/lib/crowdsec/online_api_credentials.yaml 0750 ${user} ${group} - -"
      ];

    services.crowdsec = {
      enable = true;
      autoUpdateService = true;

      settings = {
        general.api.server = {
          enable = true;
          listen_uri = "127.0.0.1:${cfg.lapiPort}";
        };

        # See https://github.com/NixOS/nixpkgs/issues/445342
        lapi.credentialsFile = "/var/lib/crowdsec/local_api_credentials.yaml";
        capi.credentialsFile = "/var/lib/crowdsec/online_api_credentials.yaml";

        console = {
          tokenFile = config.sops.secrets."crowdsec/enroll_key".path;
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

      localConfig.acquisitions = [
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
    };

    environment.systemPackages = [ pkgs.crowdsec-firewall-bouncer ];

    sops = lib.mkMerge ([ { secrets."crowdsec/enroll_key" = { }; } ] ++ bouncerSopsList);

    systemd.services = lib.mkMerge bouncerServiceList;
  };
}
