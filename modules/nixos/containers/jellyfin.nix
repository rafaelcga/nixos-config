{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers.instances;

  containerWebPort = 8096;
in
{
  config = lib.mkIf (cfg ? "jellyfin" && cfg.jellyfin.enable) {
    containers.jellyfin = {
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

          modules.nixos.graphics = lib.mkIf cfg.jellyfin.gpuPassthrough config.modules.nixos.graphics;
        };
    };

    modules.nixos.caddy = lib.mkIf config.modules.nixos.caddy.enable {
      virtualHosts.jellyfin = {
        originHost = cfg.jellyfin.localAddress;
        originPort = containerWebPort;
      };
    };
  };
}
