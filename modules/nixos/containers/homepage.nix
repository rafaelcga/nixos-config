{ config, lib, ... }:
let
  cfg_instances = config.modules.nixos.containers.instances;
  cfg = cfg_instances.homepage;

  apiKeyName = service: "HOMEPAGE_VAR_${lib.toUpper service}_API_KEY";
in
lib.mkMerge [
  {
    modules.nixos.containers.instances.homepage = {
      containerPort = 8082;
      containerDataDir = "/etc/homepage-dashboard";
    };
  }
  (lib.mkIf cfg.enable {
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
        };

        systemd.services.link-cache = {
          description = "Links cache to config directory";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              let
                cacheDir = "/var/cache/homepage-dashboard";
              in
              ''
                ln -snf "${cacheDir}" "${cfg.containerDataDir}/cache"
              '';
          };
        };
      };
    };
  })
]
