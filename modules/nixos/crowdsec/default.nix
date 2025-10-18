{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.crowdsec;
  usesCaddy = config.services.caddy.enable;
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
