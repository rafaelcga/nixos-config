{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) crowdsec;
  cfg = config.modules.nixos.caddy;

  ipUpdateServiceName = "caddy-ip-updater";
  envFile = "/var/lib/${ipUpdateServiceName}/caddy.env";

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
    tls {
        resolvers 9.9.9.9 1.1.1.1
    }

    encode

    header {
        Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; media-src 'self'; object-src 'none'; prefetch-src 'self'; child-src 'self'; frame-src 'self'; worker-src 'self'; frame-ancestors 'none'; form-action 'self'; base-uri 'self'; upgrade-insecure-requests; block-all-mixed-content;"
        Permissions-Policy "accelerometer=(), ambient-light-sensor=(), battery=(), bluetooth=(), gyroscope=(), hid=(), interest-cohort=(), magnetometer=(), serial=(), usb=(), xr-spatial-tracking=()"
        X-Content-Type-Options nosniff
        X-Frame-Options SAMEORIGIN
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Robots-Tag none
        Referrer-Policy strict-origin-when-cross-origin
    }
    header -Server
  '';

  abortNonLocal = ''
    @denied not remote_ip private_ranges {$PUBLIC_IP}
    abort @denied
  '';

  mkLogFormat =
    hostName:
    let
      fileName = "access${lib.optionalString (hostName != "") "-${hostName}"}.log";
    in
    ''
      output file ${config.services.caddy.logDir}/${fileName} {
          mode 644
          roll_size 100MiB
          roll_keep 5
          roll_keep_for 14d
      }
      format console {
          time_format rfc3339
      }
    '';

  mkRoute =
    {
      directives,
      isLocal ? false,
    }:
    ''
      ${commonBlock}
      route {
          ${lib.optionalString isLocal abortNonLocal}
          ${lib.optionalString crowdsec.enable ''
            crowdsec
            appsec
          ''}
          ${directives}
      }
    '';

  mkVirtualHost =
    name: host:
    lib.nameValuePair "${name}.{$DOMAIN}" {
      logFormat = mkLogFormat name;
      extraConfig = mkRoute {
        directives = ''
          ${host.extraConfig}
          reverse_proxy ${host.originHost}:${host.originPort}
        '';
        inherit (host) isLocal;
      };
    };

  healthEndpoint = {
    "health.{$DOMAIN}" = {
      logFormat = mkLogFormat "health";
      extraConfig = mkRoute {
        directives = "respond 200";
        isLocal = true;
      };
    };
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

      isLocal = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to serve the route only to local systems";
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
          environmentFile = envFile;
          package = pkgs.local.caddy-with-plugins;

          inherit globalConfig;
          logFormat = mkLogFormat "";
          virtualHosts = lib.recursiveUpdate (lib.mapAttrs' mkVirtualHost cfg.virtualHosts) healthEndpoint;
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

        systemd = {
          services =
            let
              inherit (config.services.caddy) user group;
            in
            {
              "${ipUpdateServiceName}" = rec {
                description = "Fetches the server's public IP and adds it as an environment variable PUBLIC_IP";
                wantedBy = [
                  "multi-user.target"
                  "caddy.service"
                ];
                before = [ "caddy.service" ];
                after = [
                  "sops-nix.service"
                  "network-online.target"
                ];
                wants = after;
                serviceConfig =
                  let
                    prevState = "/var/lib/${ipUpdateServiceName}/prev-ip";
                  in
                  {
                    Type = "oneshot";
                    Restart = "on-failure";
                    RestartSec = "10s";
                    StateDirectory = ipUpdateServiceName;
                    ExecStart = lib.getExe (
                      pkgs.writeShellApplication {
                        name = "update-caddy-ip";
                        runtimeInputs = with pkgs; [
                          coreutils
                          curl
                          systemd
                        ];
                        text = ''
                          CURR_IP="$(curl -s -m 5 https://checkip.amazonaws.com)"
                          PREV_IP="$(cat "${prevState}" 2>/dev/null || echo "$CURR_IP")"

                          if [[ -z "$CURR_IP" ]]; then
                            echo "Error: Could not fetch public IP."
                            exit 1
                          fi

                          if [[ "$CURR_IP" != "$PREV_IP" || ! -f "${envFile}" ]]; then
                            cat "${config.sops.templates."caddy-env".path}" >"${envFile}"
                            echo "PUBLIC_IP=$CURR_IP" >>"${envFile}"

                            chown ${user}:${group} "${envFile}"
                            chmod 0600 "${envFile}"

                            if systemctl is-active --quiet caddy; then
                              echo "Restarting Caddy to apply new IP..."
                              systemctl restart caddy
                            else
                              echo "Caddy is not currently active; skipping restart."
                            fi
                          fi

                          echo "$CURR_IP" >"${prevState}"
                        '';
                      }
                    );
                  };
              };
            };

          timers."${ipUpdateServiceName}" = {
            description = "Run Caddy IP Updater periodically";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnUnitActiveSec = "5min";
            };
          };

          tmpfiles.settings = {
            "10-caddy-logs" = {
              "${config.services.caddy.logDir}".d = {
                inherit (config.services.caddy) user group;
                mode = "0755";
              };
            };
          };
        };
      }
      (lib.mkIf crowdsec.enable {
        modules.nixos.crowdsec.bouncers.caddy.enable = true;

        services.crowdsec = {
          hub.collections = [ "crowdsecurity/caddy" ];

          settings.acquisitions = [
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
              apiKeyFile
              serviceName
              ;

            bouncerEnvServiceName = "caddy-bouncer-env-generator";
            bouncerEnvFile = "/var/lib/${bouncerEnvServiceName}/caddy.env";
          in
          {
            "${bouncerEnvServiceName}" = rec {
              description = "Append CrowdSec's API key to Caddy's environment variables";
              wantedBy = [ "multi-user.target" ];
              after = [
                "${serviceName}.service"
                "${ipUpdateServiceName}.service"
              ];
              wants = after;
              serviceConfig = {
                Type = "oneshot";
                StateDirectory = bouncerEnvServiceName;
                ExecStart = lib.getExe (
                  pkgs.writeShellApplication {
                    name = "add-crowdsec-api-caddy";
                    runtimeInputs = with pkgs; [ coreutils ];
                    text = ''
                      echo "CROWDSEC_API_KEY=$(cat ${apiKeyFile})" >"${bouncerEnvFile}"

                      chown ${user}:${group} "${bouncerEnvFile}"
                      chmod 0600 "${bouncerEnvFile}"
                    '';
                  }
                );
              };
            };

            caddy = rec {
              after = [ "${bouncerEnvServiceName}.service" ];
              wants = after;
              serviceConfig = {
                TimeoutStopSec = lib.mkForce "20s";
                EnvironmentFile = lib.mkForce [
                  envFile
                  bouncerEnvFile
                ];
              };
            };
          };
      })
    ]
  );
}
