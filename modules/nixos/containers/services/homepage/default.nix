{
  inputs,
  config,
  lib,
  userName,
  ...
}:
let
  cfg_containers = config.modules.nixos.containers.services;
  cfg = cfg_containers.homepage;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  hostLocalIp = config.modules.nixos.networking.staticIp;

  serviceData = import ./service-data.nix;

  getSecretName =
    service:
    let
      inherit (serviceData.${service}) container apiAuth;
      secretName = {
        key = "${container}/${service}";
        password = "passwords/services";
      };
    in
    secretName.${apiAuth};

  getEnvVarName =
    service:
    let
      inherit (serviceData.${service}) apiAuth;
      suffix = {
        key = "API_KEY";
        password = "PASSWORD";
      };
    in
    "HOMEPAGE_VAR_${lib.toUpper service}_${suffix.${apiAuth}}";
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
              "${getSecretName service}" = { };
            };
        in
        lib.concatMapAttrs mkSecret serviceData;

      templates."homepage-env".content =
        let
          mkEnvVar =
            service: data:
            lib.optionalString cfg_containers.${data.container}.enable ''
              ${getEnvVarName service}=${config.sops.placeholder.${getSecretName service}}
            '';
        in
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList mkEnvVar serviceData
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
                  containerIp = utils.removeMask config.containers.${data.container}.localAddress;
                  localPort = builtins.toString containerConfig.hostPorts.${service};
                  containerPort = builtins.toString containerConfig.containerPorts.${service};

                  hrefLocal = "http://${hostLocalIp}:${localPort}";
                  hrefContainer = "http://${containerIp}:${containerPort}";
                in
                {
                  "${data.displayName}" = lib.mkIf containerConfig.enable {
                    icon = "${service}.png";
                    href = hrefLocal;
                    widget =
                      let
                        envVarSub = "{{" + (getEnvVarName service) + "}}";
                      in
                      lib.mkMerge [
                        {
                          type = service;
                          url = hrefContainer;
                          fields = data.widgetFields;
                        }
                        (lib.mkIf (data.apiAuth == "key") {
                          key = envVarSub;
                        })
                        (lib.mkIf (data.apiAuth == "password") {
                          username = userName;
                          password = envVarSub;
                        })
                        data.extraConfig
                      ];
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
