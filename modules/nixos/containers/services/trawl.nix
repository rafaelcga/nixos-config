{
  modules.nixos.containers.services.trawl = {
    uid = 10;
    engine = "oci";
    image = "ghcr.io/germondai/trawl:latest";
    containerPort = 8191;
    dataDir = "/data/metrics";
    enableBackup = false;
    environment = {
      SESSION_CACHE_DRIVER = "memory";
      MCP_ENABLED = "true";
      METRICS_DASHBOARD_ENABLED = "true";
      SCRAPE_MIN_TIER = "2";
      BROWSER_MAX_CONTENT_PROCESSES = "4";
    };
  };
}
