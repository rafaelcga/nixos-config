{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.caddy;

  inherit (config.modules.nixos) crowdsec;
  crowdsecConfig = lib.mkIf crowdsec.enable {
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
  };

  globalConfig = builtins.concatStringsSep "\n" [
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

  envFile = builtins.concatStringsSep "\n" [
    ''
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
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        -Server
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Robots-Tag none
    }
  '';

  mkRoute =
    {
      originHost ? "localhost",
      originPort,
    }:
    let
      routeBlock = builtins.concatStringsSep "\n" [
        (lib.optionalString crowdsec.enable ''
          crowdsec
          appsec
        '')
      ];
    in
    ''
      route {
        ${routeBlock}
        reverse_proxy ${originHost}:${originPort}
      }
    '';

  mkVirtualHost =
    {
      subdomain,
      originHost ? "localhost",
      originPort,
    }:
    let
      domain = config.sops.secrets."web_domain";
      routeBlock = mkRoute { inherit originHost originPort; };
    in
    {
      "${subdomain}.${domain}".extraConfig = ''
        ${commonBlock}
        ${routeBlock}
      '';
    };
in
{
  options.modules.nixos.caddy = {
    enable = lib.mkEnableOption "Enable Caddy web server";

    virtualHosts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            subdomain = lib.mkOption {
              type = lib.types.str;
              description = "Subdomain within the web domain";
            };

            originHost = lib.mkOption {
              type = lib.types.str;
              default = "localhost";
              description = "Host to which traffic is routed";
            };

            originPort = lib.mkOption {
              type = lib.types.ints.unsigned;
              apply = builtins.toString;
              description = "Port at the origin host to which traffic is routed";
            };
          };
        }
      );
      default = [ ];
      description = "List of virtual hosts to route";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.caddy = {
          inherit globalConfig;
          enable = true;
          environmentFile = config.sops.templates."caddy-env".path;
          package = pkgs.local.caddy;
          virtualHosts = lib.mkMerge (map mkVirtualHost cfg.virtualHosts);
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
      crowdsecConfig
    ]
  );
}
