{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances;

  hostGraphicsConfig = config.modules.nixos.graphics;
in
{
  config = lib.mkIf (cfg ? "jellyfin" && cfg.jellyfin.enable) {
    containers.jellyfin = {
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

      config = lib.mkMerge [
        hostGraphicsConfig
        (
          { pkgs, ... }:
          {
            services.jellyfin = {
              enable = true;
              openFirewall = true;
            };
            environment.systemPackages = with pkgs; [
              jellyfin
              jellyfin-web
              jellyfin-ffmpeg
            ];
          }
        )
      ];
    };
  };
}
