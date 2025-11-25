{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg_containers = config.modules.nixos.containers.services;
  cfg = cfg_containers.homepage;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  hostLocalIp = config.modules.nixos.networking.staticIp;
  apiKeyName = service: "HOMEPAGE_VAR_${lib.toUpper service}_API_KEY";

  serviceData = {
    lidarr = {
      container = "servarr";
      secret = "servarr/lidarr";
      widgetFields = [
        "wanted"
        "queued"
        "artists"
      ];
    };
  };
in
lib.mkMerge [
  {
    modules.nixos.containers.services.homepage = {
      containerPort = 8082;
      containerDataDir = "/etc/homepage-dashboard";
    };
  }
  (lib.mkIf cfg.enable {
    sops = {
      secrets =
        let
          mkSecret =
            service: data:
            lib.optionalAttrs cfg_containers.${data.container}.enable {
              "${data.secret}" = { };
            };
        in
        lib.concatMapAttrs mkSecret serviceData;

      templates."homepage-env".content =
        let
          mkEnvVar =
            service: data:
            let
              envVar = ''
                ${apiKeyName service}=${config.sops.placeholder.${data.secret}}
              '';
            in
            lib.optionalString cfg_containers.${data.container}.enable envVar;
        in
        lib.concatStringsSep "\n" (
          (lib.mapAttrsToList mkEnvVar serviceData)
          ++ [
            "HOMEPAGE_ALLOWED_HOSTS=${hostLocalIp}:${builtins.toString cfg.hostPort}"
          ]
        );
    };

    containers.homepage = {
      bindMounts = {
        "${config.sops.templates."homepage-env".path}" = {
          isReadOnly = true;
        };
      };

      config = {
        services.homepage-dashboard = {
          enable = true;
          listenPort = cfg.containerPort;
          openFirewall = true;

          environmentFile = config.sops.templates."homepage-env".path;
          services =
            let
              mkService =
                service: data:
                let
                  containerConfig = cfg_containers.${data.container};
                  port = builtins.toString containerConfig.hostPorts.${service};
                  href = "http://${hostLocalIp}:${port}";
                in
                {
                  "${utils.capitalizeFirst service}" = lib.mkIf containerConfig.enable {
                    icon = "${service}.png";
                    inherit href;
                    widget = {
                      type = service;
                      url = href;
                      key = "{{${apiKeyName service}}";
                      fields = data.widgetFields;
                    };
                  };
                };

              mkGroup =
                serviceNames:
                let
                  groupServices = lib.filterAttrs (name: _: lib.elem name serviceNames) serviceData;
                in
                lib.mapAttrsToList mkService groupServices;
            in
            [
              {
                "Media Management" = mkGroup [
                  "lidarr"
                  "radarr"
                  "sonarr"
                  "prowlarr"
                  "qbittorrent"
                ];
              }
            ];
        };

        systemd.tmpfiles.settings = {
          "10-homepage-cache-symlink" = {
            "${cfg.containerDataDir}/cache" = {
              L = {
                argument = "/var/cache/homepage-dashboard";
              };
            };
          };
        };
      };
    };
  })
]
