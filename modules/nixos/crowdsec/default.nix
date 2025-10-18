{
  config,
  pkgs,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.crowdsec;
  userGroup = config.users.users.${userName}.group;
  usesCaddy = config.modules.nixos.caddy.enable;

  # https://github.com/crowdsecurity/crowdsec/blob/master/docker/docker_start.sh
  mkBouncerRegistrationService =
    { name, environmentFile }:
    {
      "register_crowdsec_${name}_bouncer" = {
        description = "Registers idempotently ${name} CrowdSec bouncer";
        serviceConfig = {
          Type = "oneshot";
          User = userName;
          Group = userGroup;
          EnvironmentFile = environmentFile;
        };
        script = ''
          if ! ${pkgs.crowdsec}/bin/cscli bouncers list -o json | ${pkgs.jq}/bin/jq -r '.[].name' | ${pkgs.gnugrep}/bin/grep -q "^$BOUNCER_NAME$"; then
              if ${pkgs.crowdsec}/bin/cscli bouncers add "$BOUNCER_NAME" -k "$BOUNCER_KEY" > /dev/null; then
                  echo "Registered bouncer for $BOUNCER_NAME"
              else
                  echo "Failed to register bouncer for $BOUNCER_NAME"
              fi
          fi
        '';
        wantedBy = [ "multi-user.target" ];
      };
    };
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
    mkBouncerRegistrationService = lib.mkOption {
      type = lib.types.functionTo lib.types.attrs;
      readOnly = true;
      default = mkBouncerRegistrationService;
      description = ''
        Generates the attribute set for configuring a systemd service registering
        a CrowdSec bouncer through a name and an environment variable file path.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.crowdsec = {
      enable = true;
      settings.general = {
        api.server.listen_uri = "127.0.0.1:${cfg.lapiPort}";
      };
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
        {
          source = "appsec";
          listen_addr = "127.0.0.1:${cfg.appsecPort}";
          appsec_configs = [
            "crowdsecurity/appsec-default"
            "crowdsecurity/appsec-generic-rules"
            "crowdsecurity/appsec-crs"
            "crowdsecurity/virtual-patching"
          ];
          labels = {
            type = "appsec";
          };
        }
      ]
      + lib.optionals usesCaddy [
        {
          source = "file";
          filename = "${config.services.caddy.logDir}/*.log";
          labels = {
            type = "caddy";
          };
        }
      ];
    };
    environment.systemPackages = [ pkgs.crowdsec-firewall-bouncer ];
  };
}
