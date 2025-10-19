{ config, lib, ... }:
let
  cfg = config.modules.containers.jellyfin;
  inherit (config.modules.containers) commonConfig;
in
{
  allowedDevices = [
    {
      node = "/dev/dri/card0";
      modifier = "rw";
    }
    {
      node = "/dev/dri/renderD128";
      modifier = "rw";
    }
  ];

  bindMounts = {
    "/dev/dri/card0" = {
      hostPath = "/dev/dri/card0";
      isReadOnly = false;
    };

    "/dev/dri/renderD128" = {
      hostPath = "/dev/dri/renderD128";
      isReadOnly = false;
    };
  };

  options.modules.containers.jellyfin = {
    enable = lib.mkEnableOption "Enable Jellyfin container";
    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [
        {
          name = "jellyfin-plugin-sso";
          url = "https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json";
        }
      ];
      description = "Plugins to enable in the Jellyfin container";
    };
  };

  config = lib.mkIf cfg.enable {
    containers.jellyfin = lib.recursiveUpdate commonConfig {
      config =
        {
          config,
          pkgs,
          ...
        }:
        let
          pluginReposToJson =
            plugins:
            builtins.toJson (
              map (plugin: {
                Name = plugin.name;
                Url = plugin.url;
                Enabled = true;
              }) plugins
            );

          enablePluginRepos =
            {
              plugins ? [ ],
            }:
            let
              systemXml = "${config.services.jellyfin.configDir}/system.xml";
              pluginJsonList = pluginReposToJson plugins;
              pluginListPath = ".ServerConfiguration.PluginRepositories.RepositoryInfo";
            in
            {
              "enable_jellyfin_plugin_repos" = {
                description = "Enables idempotently all Jellyfin plugins";
                after = [ "jellyfin.service" ];
                wants = [ "jellyfin.service" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  User = config.services.jellyfin.user;
                  Group = config.services.jellyfin.group;
                };
                # Handles the XML as JSON; ensures that the plugin list in the
                # transformed JSON is interpreted as a list (doesn't by default
                # if it only has one element)
                script = ''
                  tempFile=$(mktemp) # temp file to avoid truncating input

                  ${pkgs.yq-go}/bin/yq -oj "${pluginListPath} |= ([] + .)" ${systemXml} |
                      ${pkgs.yq-go}/bin/yq "${pluginListPath} = (${pluginListPath} + ${pluginJsonList} | unique)" |
                      ${pkgs.yq-go}/bin/yq -ox > $tempFile

                  mv "$tempFile" "${systemXml}"
                '';
              };
            };
        in
        {
          services.jellyfin = {
            enable = true;
            openFirewall = true;
          };
          environment.systemPackages = [
            pkgs.jellyfin
            pkgs.jellyfin-web
            pkgs.jellyfin-ffmpeg
          ];

          systemd.services = enablePluginRepos cfg.plugins;
        };
    };
  };
}
