{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers.instances.jellyfin or { enable = false; };
  hostDataDir = config.modules.nixos.containers.dataDir;

  dataDir = "/var/lib/jellyfin";
in
{
  config = lib.mkIf cfg.enable {
    modules.nixos.containers.instances.jellyfin.containerPort = 8096;

    containers.jellyfin = {
      bindMounts = {
        "${dataDir}" = {
          hostPath = "${hostDataDir}/jellyfin";
          isReadOnly = false;
        };
      };

      config =
        { pkgs, ... }:
        {
          imports = [ "${inputs.self}/modules/nixos" ];

          services.jellyfin = {
            enable = true;
            openFirewall = true;

            inherit dataDir;
            configDir = "${dataDir}/config";
            cacheDir = "${dataDir}/cache";
            logDir = "${dataDir}/log";
          };

          environment.systemPackages = with pkgs; [
            jellyfin
            jellyfin-web
            jellyfin-ffmpeg
          ];

          modules.nixos.graphics = lib.mkIf cfg.gpuPassthrough config.modules.nixos.graphics;
        };
    };

    modules.nixos.caddy = lib.mkIf config.modules.nixos.caddy.enable {
      virtualHosts.jellyfin = {
        originHost = cfg.localAddress;
        originPort = cfg.containerPort;
      };
    };
  };
}
