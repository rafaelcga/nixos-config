{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers.instances.jellyfin;
in
lib.mkMerge [
  {
    modules.nixos.containers.instances.jellyfin = {
      containerPort = 8096;
      containerDataDir = "/var/lib/jellyfin";
    };
  }
  (lib.mkIf cfg.enable {
    containers.jellyfin = {
      config =
        { pkgs, ... }:
        {
          imports = [ "${inputs.self}/modules/nixos/hardware/graphics.nix" ];

          services.jellyfin = {
            enable = true;
            openFirewall = true;

            dataDir = cfg.containerDataDir;
            configDir = "${cfg.containerDataDir}/config";
            cacheDir = "${cfg.containerDataDir}/cache";
            logDir = "${cfg.containerDataDir}/log";
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
  })
]
