{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) crowdsec;
  cfg = config.modules.nixos.caddy;
  cfgCaddy = config.services.caddy;

  crowdsecBouncer = crowdsec.bouncers.caddy;

  envServiceName = "caddy-env";
  envFile = "/var/lib/${envServiceName}/caddy.env";

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

  # Access logs are kept in Caddy's default JSON format, which is what
  # CrowdSec's `crowdsecurity/caddy-logs` parser expects.
  # Group-readable so that CrowdSec can read them (see `extraGroups` below).
  mkLogFormat = hostName: ''
    output file ${cfgCaddy.logDir}/access-${hostName}.log {
        mode 0640
        roll_size 100MiB
        roll_keep 5
        roll_keep_for 14d
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

  # Builds Caddy's environment file from the sops template, the current public
  # IP and (optionally) the CrowdSec bouncer API key. Caddy is only restarted
  # when the resulting file actually changes.
  generateEnv = pkgs.writeShellApplication {
    name = "generate-caddy-env";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      diffutils
      systemd
    ];
    text = ''
      SERVICES=(
        "https://checkip.amazonaws.com"
        "https://icanhazip.com"
        "https://api.ipify.org"
        "https://ifconfig.me/ip"
      )

      CURR_IP=""

      # Loop through services and stop at the first one that returns a valid IP
      for url in "''${SERVICES[@]}"; do
        res="$(curl -4 -s -f -m 3 "$url" 2>/dev/null | tr -d '[:space:]' || true)"

        # Validate that the response is strictly an IPv4 address
        if [[ "$res" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
          CURR_IP="$res"
          break
        fi
      done

      if [[ -z "$CURR_IP" ]]; then
        echo "Error: All IP lookup providers failed or returned invalid data." >&2
        exit 1
      fi

      ${lib.optionalString crowdsec.enable ''
        CROWDSEC_API_KEY="$(cat ${crowdsecBouncer.apiKeyFile})"
      ''}

      tmp="$(mktemp "${envFile}.XXXXXX")"
      trap 'rm -f "$tmp"' EXIT

      {
        cat ${config.sops.templates."caddy-env".path}
        echo "PUBLIC_IP=$CURR_IP"
        ${lib.optionalString crowdsec.enable ''echo "CROWDSEC_API_KEY=$CROWDSEC_API_KEY"''}
      } >"$tmp"

      if cmp -s "$tmp" "${envFile}"; then
        echo "Environment unchanged (public IP: $CURR_IP)"
        exit 0
      fi

      mv "$tmp" "${envFile}"
      echo "Environment updated (public IP: $CURR_IP)"

      # --no-block: Caddy is ordered after this unit, so waiting for the restart
      # job from inside this unit would deadlock
      if systemctl is-active --quiet caddy.service || systemctl is-failed --quiet caddy.service; then
        echo "Restarting Caddy to apply the new environment..."
        systemctl restart --no-block caddy.service
      fi
    '';
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
          openFirewall = true;
          environmentFile = envFile;
          package = pkgs.local.caddy-with-plugins;

          inherit globalConfig;
          # Runtime logs go to the journal; access logs are per virtual host
          logFormat = "level INFO";
          virtualHosts = lib.mapAttrs' mkVirtualHost cfg.virtualHosts // healthEndpoint;
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
          services.${envServiceName} = rec {
            description = "Generate Caddy's environment file (secrets and public IP)";
            wantedBy = [ "caddy.service" ];
            before = [ "caddy.service" ];
            after = [
              "network-online.target"
            ]
            ++ lib.optional config.sops.useSystemdActivation "sops-install-secrets.service"
            ++ lib.optional crowdsec.enable "${crowdsecBouncer.serviceName}.service";
            wants = after;
            serviceConfig = {
              Type = "oneshot";
              Restart = "on-failure";
              RestartSec = "10s";
              StateDirectory = envServiceName;
              UMask = "0077";
              ExecStart = lib.getExe generateEnv;
            };
          };

          timers.${envServiceName} = {
            description = "Periodically refresh Caddy's environment file";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "5min";
              OnUnitActiveSec = "5min";
            };
          };
        };
      }
      (lib.mkIf crowdsec.enable {
        modules.nixos.crowdsec.bouncers.caddy.enable = true;

        services.crowdsec = {
          hub.collections = [ "crowdsecurity/caddy" ];

          # Allow reading Caddy's (group-readable) access logs
          extraGroups = [ cfgCaddy.group ];

          settings.acquisitions = [
            {
              source = "file";
              filenames = [ "${cfgCaddy.logDir}/access-*.log" ];
              labels.type = "caddy";
            }
          ];
        };

        systemd.services.caddy.serviceConfig.TimeoutStopSec = "20s";
      })
    ]
  );
}
