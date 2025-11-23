{
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.servarr;

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
                dataDir = "${cfg.containerDataDir}/${name}";
                settings = {
                  server.port = cfg.containerPorts.${name};
                  update = {
                    mechanism = "builtIn";
                    automatically = true;
                  };
                };
                environmentFiles = [ config.sops.templates."servarr-env".path ];
                openFirewall = true;
              }
              // lib.optionalAttrs (name != "prowlarr") {
                user = userName;
              };
          in
          lib.genAttrs services mkService;
      };
    };
  })
]
