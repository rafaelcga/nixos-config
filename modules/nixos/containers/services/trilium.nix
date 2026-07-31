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
      };
    };
  })
]
