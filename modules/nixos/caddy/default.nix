{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.caddy;
  usesCrowdsec = config.services.crowdsec.enable;

  globalConfig = ''
    acme_dns porkbun {
        api_key {$PORKBUN_API_KEY}
        api_secret_key {$PORKBUN_SECRET_API_KEY}
    }
  ''
  + lib.optionalString usesCrowdsec (
    "\n"
    + ''
      crowdsec {
          api_url http://localhost:8080
          api_key {$CROWDSEC_API_KEY}
          appsec_url http://localhost:7422
      }
    ''
  );
  encodeBlock = "encode";
  accessBlock = ''
    log {
        output file /var/log/caddy/access.log {
            roll_size 100MiB
            roll_keep 5
            roll_keep_for 14d
        }
        format console {
            time_format rfc3339
        }
    }
  '';
  headerBlock = ''
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        -Server
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Robots-Tag none
    }
  '';
in
{
  options.modules.nixos.caddy = {
    enable = lib.mkEnableOption "Caddy configuration";
    mkProxyConfig =
      {
        host ? "localhost",
        port,
      }:
      let
        proxyBlock = "reverse_proxy ${host}:${port}";
        routeBlock =
          if usesCrowdsec then
            ''
              route {
                  crowdsec
                  appsec
                  ${proxyBlock}
              }
            ''
          else
            proxyBlock;
      in
      ''
        ${encodeBlock}
        ${accessBlock}
        ${headerBlock}
        ${routeBlock}
      '';
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      inherit globalConfig;
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/caddy-dns/porkbun@main"
        ]
        + lib.optionals usesCrowdsec [
          "github.com/hslatman/caddy-crowdsec-bouncer/http@main"
          "github.com/hslatman/caddy-crowdsec-bouncer/appsec@main"
          "github.com/hslatman/caddy-crowdsec-bouncer/layer4@main"
        ];
      };
    };
    # HTTP/HTTPS ports
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
