{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.services.servarr;
  cfgSops = config.sops;

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
      containerDataDir = "/var/lib/servarr";
      behindVpn = true;
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
              apiKey = cfgSops.placeholder."servarr/${service}";
            in
            "${lib.toUpper service}__AUTH__APIKEY=${apiKey}";
        in
        lib.concatMapStringsSep "\n" mkApiKey services;
    };

    containers.servarr = {
      bindMounts = {
        "${cfgSops.templates."servarr-env".path}" = {
          isReadOnly = true;
        };
      };

      config =
        { config, ... }:
        {
          services =
            let
              mkService =
                name:
                {
                  enable = true;
                  dataDir = "${cfg.containerDataDir}/${name}";
                  settings.server.port = cfg.containerPorts.${name};
                  environmentFiles = [ cfgSops.templates."servarr-env".path ];
                  openFirewall = true;
                }
                // lib.optionalAttrs (name != "prowlarr") {
                  user = cfg.name;
                  inherit (config.users.users.${cfg.name}) group;
                };
            in
            lib.genAttrs services mkService;
        };
    };
  })
]
