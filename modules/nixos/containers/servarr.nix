{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances.servarr;

  servarrServices = [
    "lidarr"
    "radarr"
    "sonarr"
    "prowlarr"
  ];

  mkApiKey =
    service:
    let
      apiKey = config.sops.placeholder."servarr/${service}";
    in
    "${lib.toUpper service}__AUTH__APIKEY=${apiKey}";
in
lib.mkMerge [
  {
    modules.nixos.containers.instances.servarr = {
      containerPorts = {
        lidarr = 8686;
        radarr = 7878;
        sonarr = 8989;
        prowlarr = 9696;
      };
      containerDataDir = "/var/lib/servarr";
      behindVpn = true;
    };
  }
  (lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "servarr/lidarr" = { };
        "servarr/radarr" = { };
        "servarr/sonarr" = { };
        "servarr/prowlarr" = { };
      };
      templates."servarr-env".content = lib.concatMapStringsSep "\n" mkApiKey servarrServices;
    };

    containers.servarr = {
      bindMounts = {
        "${config.sops.templates."servarr-env".path}" = {
          isReadOnly = true;
        };
      };

      config = {
        services =
          let
            mkService = name: {
              enable = true;
              dataDir = "${cfg.containerDataDir}/${name}";
              settings.server.port = cfg.containerPorts.${name};
              environmentFiles = [ config.sops.templates."servarr-env".path ];
              openFirewall = true;
            };
          in
          lib.genAttrs servarrServices mkService;
      };
    };
  })
]
