{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.trilium;
  configModules = config.modules.nixos;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.trilium = {
      uid = 9;
      containerPort = 8080;
      dataDir = "/var/lib/trilium";
    };
  }
  (lib.mkIf cfg.enable {
    containers.trilium = {
      config = {
        services.trilium-server = {
          inherit (cfg) enable dataDir;
          host = "0.0.0.0";
          port = cfg.containerPort;

          environmentFile = pkgs.writeText "trilium.env" ''
            TRILIUM_NETWORK_TRUSTEDREVERSEPROXY=1
          '';
        };

        networking.firewall.allowedTCPPorts = [ cfg.containerPort ];
      };
    };

    modules.nixos.caddy = lib.mkIf configModules.caddy.enable {
      virtualHosts.trilium = {
        originHost = cfg.address;
        originPort = cfg.containerPort;
        extraConfig = ''
          header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https:; font-src 'self' data:; connect-src 'self' ws: wss: http: https:; worker-src 'self' blob:; frame-src 'self' blob:; frame-ancestors 'self';"
          header -X-Frame-Options
        '';
      };
    };
  })
]
