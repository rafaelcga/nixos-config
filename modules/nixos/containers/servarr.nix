{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances.servarr;

  servarrServices = [
    "lidarr"
    "radarr"
    "sonarr"
    "prowlarr"
  ];
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
    };
  }
  (lib.mkIf cfg.enable {
    containers.servarr = {
      enableTun = true;

      config = {
        services =
          let
            mkService = name: {
              enable = true;
              dataDir = "${cfg.containerDataDir}/${name}";
              settings.server.port = cfg.containerPorts.${name};
            };
          in
          lib.genAttrs servarrServices mkService;
      };
    };
  })
]
