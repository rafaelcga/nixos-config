{ config, lib, ... }:
let
  cfg_containers = config.modules.nixos.containers.services;
  cfg = cfg_containers.servarr;
  inherit (config.modules.nixos.containers) user dataDir;

  services = lib.attrNames cfg.containerPorts;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.servarr = {
      containerPorts = {
        lidarr = 8686;
        radarr = 7878;
        sonarr = 8989;
        prowlarr = 9696;
      };
      dataDir = "/var/lib/servarr";
      behindVpn = true;

      userMounts = lib.mkIf cfg_containers.qbittorrent.enable {
        "${cfg_containers.qbittorrent.dataDir}/downloads" = {
          hostPath = "${dataDir}/qbittorrent/downloads";
          isReadOnly = false;
        };
      };
    };
  }
  (lib.mkIf cfg.enable {
    sops = {
      secrets =
        let
          mkSecret = service: lib.nameValuePair "servarr/${service}" { };
        in
        lib.genAttrs' services mkSecret;

      templates."servarr-env".content =
        let
          mkApiKey =
            service:
            let
              apiKey = config.sops.placeholder."servarr/${service}";
            in
            "${lib.toUpper service}__AUTH__APIKEY=${apiKey}";
        in
        lib.concatMapStringsSep "\n" mkApiKey services;
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
            mkService =
              name:
              {
                enable = true;
                dataDir = "${cfg.dataDir}/${name}";
                settings.server.port = cfg.containerPorts.${name};
                environmentFiles = [ config.sops.templates."servarr-env".path ];
                openFirewall = true;
              }
              // lib.optionalAttrs (name != "prowlarr") {
                user = user.name;
                inherit (user) group;
              };
          in
          lib.genAttrs services mkService;
      };
    };
  })
]
