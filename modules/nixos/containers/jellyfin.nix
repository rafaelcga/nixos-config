{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers.instances;
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

      config =
        { pkgs, ... }:
        {
          imports = [ "${inputs.self}/modules/nixos/hardware/graphics.nix" ];

          services.jellyfin = {
            enable = true;
            openFirewall = true;
          };
          environment.systemPackages = with pkgs; [
            jellyfin
            jellyfin-web
            jellyfin-ffmpeg
          ];

          modules.nixos.graphics = config.modules.nixos.graphics;
        };
    };

    modules.nixos.caddy = lib.mkIf config.modules.nixos.caddy.enable {
      virtualHosts.jellyfin = {
        originHost = cfg.jellyfin.localAddress;
        originPort = 8096;
      };
    };
  };
}
