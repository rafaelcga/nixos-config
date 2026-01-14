{
  inputs,
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg_containers = config.modules.nixos.containers.services;
  cfg = cfg_containers.homepage;
  inherit (config.modules.nixos) caddy;
  inherit (config.modules.nixos.containers) bridge;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  hostLocalIp = config.modules.nixos.networking.staticIp;
  serviceData = import ./service-data.nix { inherit inputs lib; };

  needsSecret =
    data:
    let
      isEnabled = cfg_containers.${data.container}.enable;
      hasSecret = data.apiAuth != null;
    in
    isEnabled && hasSecret;

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

  homepageLogoPath = "/icons/nix-pastel.svg";
  homepageOverride = pkgs.homepage-dashboard;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.homepage = {
      containerPort = 8082;
      dataDir = "/etc/homepage-dashboard";
    };
  }
  (lib.mkIf cfg.enable {
    sops = {
      secrets =
        let
          mkSecret =
            service: data:
            lib.optionalAttrs (needsSecret data) {
              "${getSecretName service}" = { };
            };
        in
        lib.concatMapAttrs mkSecret serviceData;

      templates."homepage-env".content =
        let
          mkEnvVar =
            service: data:
            lib.optionalString (needsSecret data) ''
              ${getEnvVarName service}=${config.sops.placeholder.${getSecretName service}}
            '';
        in
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList mkEnvVar serviceData
          ++ [
            "HOMEPAGE_ALLOWED_HOSTS=${hostLocalIp}:${toString cfg.hostPort}"
          ]
        );
    };

    networking.firewall.interfaces."${bridge.name}" = {
      allowedTCPPorts = lib.optionals caddy.enable [ caddy.adminPort ];
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
          package = homepageOverride;

          listenPort = cfg.containerPort;
          openFirewall = true;
          environmentFile = config.sops.templates."homepage-env".path;

          settings = {
            title = "${config.networking.hostName}/Homepage";
            color = "gray";
            iconStyle = "theme";
            headerStyle = "boxed";
            useEqualHeights = true;
            disableCollapse = true;
            hideVersion = true;
            disableUpdateCheck = true;
            statusStyle = "dot";

            layout = {
              "Media Management" = {
                style = "column";
                icon = "mdi-multimedia";
              };
              "Media Streaming" = {
                style = "column";
                icon = "mdi-broadcast";
              };
              "Home Network" = {
                style = "column";
                icon = "mdi-router-network-wireless";
              };
              "Game Servers" = {
                style = "column";
                icon = "mdi-controller";
              };
              "Release Calendar" = {
                style = "column";
                icon = "mdi-calendar";
              };
            };
          };

          services =
            let
              mkService =
                service: data:
                let
                  containerConfig = cfg_containers.${data.container};
                  hostPort = toString containerConfig.hostPorts.${service};
                  containerPort = toString containerConfig.containerPorts.${service};
                  serviceUrl = "${data.protocol}://${containerConfig.address}:${containerPort}";
                in
                {
                  "${data.displayName}" = lib.mkIf containerConfig.enable {
                    inherit (data) icon description;

                    href = "http://${hostLocalIp}:${hostPort}";
                    siteMonitor = lib.mkIf (data.protocol == "http") serviceUrl;

                    widget =
                      let
                        authConfig = lib.optionalAttrs (data.apiAuth != null) {
                          "${data.apiAuth}" = "{{" + (getEnvVarName service) + "}}";
                          username = lib.mkIf (data.apiAuth == "password") userName;
                        };
                      in
                      lib.mkIf (data.widgetFields != [ ]) (
                        lib.mkMerge [
                          {
                            inherit (data) type;
                            url = serviceUrl;
                            fields = data.widgetFields;
                          }
                          authConfig
                          data.extraConfig
                        ]
                      );
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
              {
                "Media Streaming" = mkGroup [
                  "jellyfin"
                ];
              }
              {
                "Home Network" = [
                  (
                    let
                      adminUrl = "http://${bridge.ipv4.host}:${toString caddy.adminPort}";
                    in
                    lib.optionalAttrs caddy.enable {
                      "Caddy" = {
                        icon = "caddy.svg";
                        description = "Web server with automatic HTTPS";
                        siteMonitor = "${adminUrl}/config/";
                        widget = {
                          type = "caddy";
                          url = adminUrl;
                        };
                      };
                    }
                  )
                ]
                ++ (mkGroup [
                  "adguard"
                  "ddns-updater"
                ]);
              }
              {
                "Game Servers" = mkGroup [
                  "minecraft"
                ];
              }
              {
                "Release Calendar" = [
                  {
                    "" = {
                      widget = {
                        type = "calendar";
                        firstDayInWeek = "monday";
                        view = "monthly";
                        maxEvents = 10;
                        showTime = true;
                        integrations =
                          let
                            template = service: {
                              type = service;
                              service_group = "Media Management";
                              service_name = utils.capitalizeFirst service;
                              params = {
                                unmonitored = false;
                              };
                            };
                          in
                          lib.map template [
                            "lidarr"
                            "radarr"
                            "sonarr"
                          ];
                      };
                    };
                  }
                ];
              }
            ];

          widgets = [
            {
              logo = {
                icon = homepageLogoPath;
              };
            }
            {
              resources = {
                label = "System";
                cpu = true;
                memory = true;
                cputemp = true;
                tempmax = 100;
                units = "metric";
              };
            }
            {
              resources = {
                label = "Storage";
                disk = [ "/" ] ++ lib.unique (lib.attrNames cfg.userMounts);
              };
            }
          ];
        };

        systemd.tmpfiles.settings = {
          "10-homepage-cache-symlink" = {
            "${cfg.dataDir}/cache".L = {
              argument = "/var/cache/homepage-dashboard";
            };
          };
        };
      };
    };
  })
]
