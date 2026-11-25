{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.services.ddns-updater;

  configPath = config.sops.templates."ddns-updater/config.json".path;
  credentialName = "config.json";
in
lib.mkMerge [
  {
    modules.nixos.containers.services.ddns-updater = {
      uid = 3;
      containerPort = 8000;
    };
  }
  (lib.mkIf cfg.enable {
    sops = {
      # Restart the consumer when a rotated secret changes
      templates."ddns-updater/config.json".restartUnits = [ "container@ddns-updater.service" ];
      secrets = {
        "web_domain".sopsFile = config.modules.nixos.sops-nix.commonSopsFile;
        "porkbun/api_key" = { };
        "porkbun/api_secret_key" = { };
      };
      # https://github.com/qdm12/ddns-updater/blob/master/docs/porkbun.md
      # Holds the Porkbun keys: kept root-only (sops-nix default 0400) and
      # handed to the service as a systemd credential, so the shared container
      # UID can't read it
      templates."ddns-updater/config.json" = {
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
        "${configPath}".isReadOnly = true;
      };

      config = {
        services.ddns-updater = {
          enable = true;
          environment = {
            # %d: the unit's credentials directory
            CONFIG_FILEPATH = "%d/${credentialName}";
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

        # Runs with the upstream module's DynamicUser instead of the shared
        # container UID. Container root, which owns the bind-mounted secret
        # (identity mapping), loads it into the service's private credentials
        systemd.services.ddns-updater.serviceConfig.LoadCredential = [
          "${credentialName}:${configPath}"
        ];

        networking.firewall.allowedTCPPorts = [ cfg.containerPort ];
      };
    };
  })
]
