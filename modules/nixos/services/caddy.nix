{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) crowdsec;
  cfg = config.modules.nixos.caddy;

  globalConfig = lib.concatStringsSep "\n" (
    [
      ''
        admin :${toString cfg.adminPort}

        acme_dns porkbun {
            api_key {$PORKBUN_API_KEY}
            api_secret_key {$PORKBUN_API_SECRET_KEY}
        }
      ''
      (lib.optionalString crowdsec.enable ''
        crowdsec {
            api_url http://127.0.0.1:${crowdsec.lapiPort}
            api_key {$CROWDSEC_API_KEY}
            appsec_url http://127.0.0.1:${crowdsec.appsecPort}
        }
      '')
    ]
    # Append extra global config from virtual hosts
    ++ lib.mapAttrsToList (_: host: host.extraGlobalConfig) cfg.virtualHosts
  );

  commonBlock = ''
    encode

    header {
        Content-Security-Policy "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self'; img-src 'self' data:; font-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'self'; upgrade-insecure-requests;"
        Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), gyroscope=(), hid=(), interest-cohort=(), magnetometer=(), serial=(), usb=(), xr-spatial-tracking=()"
        X-Content-Type-Options nosniff
        X-Frame-Options SAMEORIGIN
        -Server
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Robots-Tag none
        Referrer-Policy strict-origin-when-cross-origin
    }
  '';

  mkVirtualHost =
    name: host:
    let
      preProxyBlock = lib.concatStringsSep "\n" [
        commonBlock
        host.extraConfig
        (lib.optionalString crowdsec.enable ''
          crowdsec
          appsec
        '')
      ];
    in
    lib.nameValuePair "${name}.{$DOMAIN}" {
      extraConfig = ''
        route {
            ${preProxyBlock}
            reverse_proxy ${host.originHost}:${host.originPort}
        }
      '';
      logFormat = null;
    };

  virtualHostOpts = {
    options = {
      originHost = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "Host to which traffic is routed";
      };

      originPort = lib.mkOption {
        type = lib.types.port;
        apply = toString;
        description = "Port at the origin host to which traffic is routed";
      };

      extraGlobalConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Additional lines of configuration appended to the global configuration
          in the automatically generated `Caddyfile`
        '';
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Additional lines of configuration appended to this virtual host in the
          automatically generated `Caddyfile`
        '';
      };
    };
  };
in
{
  options.modules.nixos.caddy = {
    enable = lib.mkEnableOption "Enable Caddy web server";

    adminPort = lib.mkOption {
      type = lib.types.port;
      default = 2019;
      description = "Listening port of the admin API";
    };

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
          enable = true;
          enableReload = false; # Needs to be false for admin API to work
          environmentFile = config.sops.templates."caddy-env".path;
          package = pkgs.local.caddy-with-plugins;

          inherit globalConfig;
          logFormat = ''
            output file ${config.services.caddy.logDir}/access.log {
                mode 644
                roll_size 100MiB
                roll_keep 5
                roll_keep_for 14d
            }
            format console {
                time_format rfc3339
            }
          '';
          virtualHosts = lib.mapAttrs' mkVirtualHost cfg.virtualHosts;
        };

        networking.firewall =
          let
            httpPorts = [ 80 ];
            httpsPorts = [ 443 ];
          in
          {
            allowedTCPPorts = httpPorts ++ httpsPorts;
            allowedUDPPorts = httpsPorts;
          };

        sops = {
          secrets = {
            "web_domain" = { };
            "porkbun/api_key" = { };
            "porkbun/api_secret_key" = { };
          };

          templates."caddy-env".content = ''
            DOMAIN=${config.sops.placeholder."web_domain"}
            PORKBUN_API_KEY=${config.sops.placeholder."porkbun/api_key"}
            PORKBUN_API_SECRET_KEY=${config.sops.placeholder."porkbun/api_secret_key"}
          '';
        };

        systemd.tmpfiles.settings = {
          "10-caddy-logs" = {
            "${config.services.caddy.logDir}".d = {
              inherit (config.services.caddy) user group;
              mode = "0755";
            };
          };
        };
      }
      (lib.mkIf crowdsec.enable {
        modules.nixos.crowdsec.bouncers.caddy.enable = true;

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

        systemd.services =
          let
            inherit (config.services.caddy) user group;
            inherit (crowdsec.bouncers.caddy)
              bouncerName
              apiKeyFile
              serviceName
              ;

            envFile = "/run/${bouncerName}/caddy.env";
            genServiceName = "generate-caddy-env-file";
          in
          {
            "${genServiceName}" = rec {
              description = "Append CrowdSec's API key to Caddy's environment variables";
              wantedBy = [ "multi-user.target" ];
              after = [ "${serviceName}.service" ];
              wants = after;
              serviceConfig =
                let
                  cat = lib.getExe' pkgs.coreutils "cat";
                  chmod = lib.getExe' pkgs.coreutils "chmod";
                  chown = lib.getExe' pkgs.coreutils "chown";
                  echo = lib.getExe' pkgs.coreutils "echo";
                  mkdir = lib.getExe' pkgs.coreutils "mkdir";
                in
                {
                  Type = "oneshot";
                  ExecStartPre = "${mkdir} -p \"${dirOf envFile}\"";
                  ExecStart = pkgs.writeShellScript "caddy/add_crowdsec_api.sh" ''
                    ${cat} ${config.sops.templates."caddy-env".path} >"${envFile}"
                    ${echo} "CROWDSEC_API_KEY=$(${cat} ${apiKeyFile})" >>"${envFile}"
                  '';
                  ExecStartPost = [
                    "${chown} ${user}:${group} \"${envFile}\""
                    "${chmod} 0600 \"${envFile}\""
                  ];
                };
            };

            caddy = rec {
              after = [ "${genServiceName}.service" ];
              wants = after;
              serviceConfig = {
                TimeoutStopSec = lib.mkForce "20s";
                EnvironmentFile = lib.mkForce envFile;
              };
            };
          };
      })
    ]
  );
}
