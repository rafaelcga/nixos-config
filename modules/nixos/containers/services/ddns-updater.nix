{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.services.ddns-updater;
  inherit (config.modules.nixos.containers) user;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.ddns-updater = {
      containerPort = 8000;
    };
  }
  (lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "web_domain" = { };
        "porkbun/api_key" = { };
        "porkbun/api_secret_key" = { };
      };
      # https://github.com/qdm12/ddns-updater/blob/master/docs/porkbun.md
      templates."ddns-updater/config.json" = {
        owner = "container";
        content = ''
          {
            "settings": [
              {
                "provider": "porkbun",
                "domain": "*.${config.sops.placeholder."web_domain"}",
                "api_key": "${config.sops.placeholder."porkbun/api_key"}",
                "secret_api_key": "${config.sops.placeholder."porkbun/api_secret_key"}"
              }
            ]
          }
        '';
      };
    };

    containers.ddns-updater = {
      bindMounts = {
        "${config.sops.templates."ddns-updater/config.json".path}" = {
          isReadOnly = true;
        };
      };

      config = {
        services.ddns-updater = {
          enable = true;
          environment = {
            CONFIG_FILEPATH = config.sops.templates."ddns-updater/config.json".path;
            PERIOD = "5m";
            UPDATE_COOLDOWN_PERIOD = "5m";
            PUBLICIP_FETCHERS = "all";
            PUBLICIP_HTTP_PROVIDERS = "all";
            PUBLICIPV4_HTTP_PROVIDERS = "all";
            PUBLICIPV6_HTTP_PROVIDERS = "all";
            PUBLICIP_DNS_PROVIDERS = "all";
            PUBLICIP_DNS_TIMEOUT = "3s";
            HTTP_TIMEOUT = "10s";
            LISTENING_ADDRESS = ":${toString cfg.containerPort}";
            RESOLVER_ADDRESS = "9.9.9.9:53";
            TZ = "Europe/Madrid";
          };
        };

        systemd.services.ddns-updater = {
          serviceConfig = {
            DynamicUser = lib.mkForce false;
            User = user.name;
            Group = user.group;
          };
        };

        networking.firewall.allowedTCPPorts = [ cfg.containerPort ];
      };
    };
  })
]
