{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.minecraft;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.minecraft = {
      containerPort = 25565;
      dataDir = "/var/lib/minecraft";
    };
  }
  (lib.mkIf cfg.enable {
    containers.minecraft = {
      config = {
        services.minecraft-server = {
          enable = true;
          eula = true;

          package = pkgs.papermc;
          inherit (cfg) dataDir;
          openFirewall = true;

          jvmOpts = "-Xms6G -Xmx6G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1";

          declarative = true;
          serverProperties = {
            server-port = cfg.containerPort;
            pause-when-empty-seconds = 60;
          };
        };
      };
    };
  })
]
