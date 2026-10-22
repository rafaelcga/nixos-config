{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.trilium;
  inherit (config.modules.nixos.containers) user;
  configModules = config.modules.nixos;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.trilium = {
      uid = 9;
      engine = "oci";
      image = "docker.io/triliumnext/trilium:latest";
      containerPort = 8080;
      dataDir = "/home/node/trilium-data";
    };
  }
  (lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.trilium.environment = {
      TRILIUM_NETWORK_TRUSTEDREVERSEPROXY = "1";
      PUID = "${toString user.uid}";
      PGID = "${toString config.users.groups.${user.group}.gid}";
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
