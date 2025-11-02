{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers.instances.jellyfin or { enable = false; };

  containerWebPort = 8096;
in
{
  config = lib.mkIf cfg.enable {
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

          modules.nixos.graphics = lib.mkIf cfg.gpuPassthrough config.modules.nixos.graphics;
        };
    };

    modules.nixos.caddy = lib.mkIf config.modules.nixos.caddy.enable {
      virtualHosts.jellyfin = {
        originHost = cfg.localAddress;
        originPort = containerWebPort;
      };
    };
  };
}
