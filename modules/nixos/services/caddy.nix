{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) crowdsec;
  cfg = config.modules.nixos.caddy;

  globalConfig = lib.concatStringsSep "\n" [
    ''
      acme_dns porkbun {
          api_key {$PORKBUN_API_KEY}
          api_secret_key {$PORKBUN_API_SECRET_KEY}
      }
    ''
    (lib.optionalString crowdsec.enable ''
      crowdsec {
          api_url http://localhost:${crowdsec.lapiPort}
          api_key {$CROWDSEC_API_KEY}
          appsec_url http://localhost:${crowdsec.appsecPort}
      }
    '')
  ];

  secrets = {
    "web_domain" = { };
    "porkbun/api_key" = { };
    "porkbun/api_secret_key" = { };
    "crowdsec/caddy_bouncer_key" = lib.mkIf crowdsec.enable { };
  };

  envFile = lib.concatStringsSep "\n" [
    ''
      DOMAIN=${config.sops.placeholder."web_domain"}
      PORKBUN_API_KEY=${config.sops.placeholder."porkbun/api_key"}
      PORKBUN_API_SECRET_KEY=${config.sops.placeholder."porkbun/api_secret_key"}
    ''
    (lib.optionalString crowdsec.enable ''
      CROWDSEC_API_KEY=${config.sops.placeholder."crowdsec/caddy_bouncer_key"}
    '')
  ];

  commonBlock = ''
    encode

    log {
        output file ${config.services.caddy.logDir}/access.log {
            roll_size 100MiB
            roll_keep 5
            roll_keep_for 14d
        }
        format console {
            time_format rfc3339
        }
    }

    header {
        Content-Security-Policy "default-src 'self'; base-uri 'self'; form-action 'self'; frame-ancestors 'self'; object-src 'none'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.gstatic.com https://www.youtube.com blob:; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https:; font-src 'self' data:; connect-src 'self' wss:; worker-src 'self' blob:; media-src 'self' data: blob: https://www.youtube.com;"
        Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), gyroscope=(), hid=(), interest-cohort=(), magnetometer=(), serial=(), usb=(), xr-spatial-tracking=()"
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        -Server
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Robots-Tag none
        Referrer-Policy no-referrer
    }

    @webos header_regexp User-Agent (Web0S|WebAppManager|NetCast|SmartTV)
    header @webos {
        -Content-Security-Policy
        -X-Frame-Options
    }
  '';

  mkVirtualHost =
    name: host:
    let
      preProxyBlock = lib.concatStringsSep "\n" [
        (lib.optionalString crowdsec.enable ''
          crowdsec
          appsec
        '')
      ];
      hostConfig = {
        extraConfig = ''
          ${commonBlock}
          route {
              ${preProxyBlock}
              reverse_proxy ${host.originHost}:${host.originPort}
          }
        '';
      };
    in
    lib.nameValuePair "${name}.{$DOMAIN}" hostConfig;

  virtualHostOpts = {
    options = {
      originHost = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "Host to which traffic is routed";
      };

      originPort = lib.mkOption {
        type = lib.types.port;
        apply = builtins.toString;
        description = "Port at the origin host to which traffic is routed";
      };
    };
  };
in
{
  options.modules.nixos.caddy = {
    enable = lib.mkEnableOption "Enable Caddy web server";

    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule virtualHostOpts);
      default = { };
      description = "Attribute set with virtual hosts to route";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.caddy = {
          inherit globalConfig;
          enable = true;
          environmentFile = config.sops.templates."caddy-env".path;
          package = pkgs.local.caddy-with-plugins;
          virtualHosts = lib.mapAttrs' mkVirtualHost cfg.virtualHosts;
        };

        # HTTP/HTTPS ports
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        sops = {
          inherit secrets;
          templates."caddy-env".content = envFile;
        };
      }
      (lib.mkIf crowdsec.enable {
        services.crowdsec = {
          hub.collections = [ "crowdsecurity/caddy" ];
          localConfig.acquisitions = [
            {
              source = "file";
              filenames = [ "${config.services.caddy.logDir}/*.log" ];
              labels = {
                type = "caddy";
              };
            }
          ];
        };
        modules.nixos.crowdsec.bouncers = [ "caddy" ];
      })
    ]
  );
}
