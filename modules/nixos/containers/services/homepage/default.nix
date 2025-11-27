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

  homepageLogoPath = "/icons/nix-pastel.svg";
  homepageOverride =
    let
      nixLogoPath = "${inputs.self}/resources/splash/nix-snowflake-rainbow-pastel.svg";
    in
    pkgs.homepage-dashboard.overrideAttrs (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        mkdir -p $out/share/homepage/public/icons
        cp ${nixLogoPath} $out/share/homepage/public${homepageLogoPath}
      '';
    });
in
lib.mkMerge [
  {
    modules.nixos.containers.services.homepage = {
      containerPort = 8082;
      containerDataDir = "/etc/homepage-dashboard";
    };
  }
  (lib.mkIf cfg.enable {
    sops =
      let
        needsSecret =
          data:
          let
            isEnabled = cfg_containers.${data.container}.enable;
            hasSecret = data.apiAuth != null;
          in
          isEnabled && hasSecret;
      in
      {
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
                  containerIp = utils.removeMask config.containers.${data.container}.localAddress;
                  localPort = builtins.toString containerConfig.hostPorts.${service};
                  containerPort = builtins.toString containerConfig.containerPorts.${service};

                  hrefLocal = "http://${hostLocalIp}:${localPort}";
                  hrefService = "http://${containerIp}:${containerPort}";
                in
                {
                  "${data.displayName}" = lib.mkIf containerConfig.enable {
                    icon = "${service}.png";
                    inherit (data) description;

                    href = hrefLocal;
                    siteMonitor = hrefService;

                    widget =
                      let
                        envVarSub = "{{" + (getEnvVarName service) + "}}";
                      in
                      lib.mkIf (data.apiAuth != null) (
                        lib.mkMerge [
                          {
                            type = service;
                            url = hrefService;
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
                "Home Network" = mkGroup [
                  "ddns-updater"
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
            "${cfg.containerDataDir}/cache".L = {
              argument = "/var/cache/homepage-dashboard";
            };
          };
        };
      };
    };
  })
]
