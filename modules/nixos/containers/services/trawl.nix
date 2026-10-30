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
    };
  }
  (lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.trawl.environment = {
      SESSION_CACHE_DRIVER = "memory";
      MCP_ENABLED = true;
      METRICS_DASHBOARD_ENABLED = true;
    };
  })
]
