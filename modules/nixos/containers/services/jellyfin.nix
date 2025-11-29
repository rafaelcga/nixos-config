{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.jellyfin;
  inherit (config.modules.nixos.containers) user;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.jellyfin = {
      containerPort = 8096;
      dataDir = "/var/lib/jellyfin";
    };
  }
  (lib.mkIf cfg.enable {
    containers.jellyfin = {
      config =
        { pkgs, ... }:
        {
          imports = [ "${inputs.self}/modules/nixos/hardware/graphics.nix" ];

          _module.args.userName = user.name;

          services.jellyfin = {
            enable = true;
            user = user.name;
            inherit (user) group;
            openFirewall = true;

            inherit (cfg) dataDir;
            configDir = "${cfg.dataDir}/config";
            cacheDir = "${cfg.dataDir}/cache";
            logDir = "${cfg.dataDir}/log";
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
        originHost = cfg.address;
        originPort = cfg.containerPort;
      };
    };
  })
]
