{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.services.trawl;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.trawl = {
      uid = 10;
      engine = "oci";
      image = "ghcr.io/germondai/trawl:latest";
      containerPort = 8191;
      dataDir = "/data/metrics";
      behindVpn = true;
      enableBackup = false;
      environment = {
        SESSION_CACHE_DRIVER = "memory";
        METRICS_DASHBOARD_ENABLED = "true";
        BROWSER_MAX_CONTENT_PROCESSES = "4";
      };
    };
  }
  (lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.trawl.extraOptions = [ "--shm-size=1g" ];
  })
]
