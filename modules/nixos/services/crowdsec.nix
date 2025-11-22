{ config, lib, ... }:
let
  cfg = config.modules.nixos.crowdsec;
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
  };

  config = lib.mkIf cfg.enable {
    # See https://github.com/nixos/nixpkgs/issues/446764
    systemd.tmpfiles.settings =
      let
        inherit (config.services.crowdsec) user group;
      in
      {
        "10-crowdsec" = {
          "/var/lib/crowdsec" = {
            d = {
              inherit user group;
              mode = "0755";
            };
          };
          "/var/lib/crowdsec/online_api_credentials.yaml" = {
            f = {
              inherit user group;
              mode = "0750";
            };
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

      crowdsec-firewall-bouncer = {
        enable = true;
        secrets.apiKeyPath = config.sops.secrets."crowdsec/bouncers/firewall_key".path;
      };
    };

    sops.secrets = {
      "crowdsec/enroll_key" = { };
      "crowdsec/bouncers/firewall_key" = { };
    };
  };
}
