{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.minecraft;
  inherit (config.modules.nixos.containers) user;

  minecraftPort = 25565;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.minecraft = {
      hostPort = minecraftPort;
      containerPort = minecraftPort;
      dataDir = "/var/lib/minecraft";
    };
  }
  (lib.mkIf cfg.enable {
    containers.minecraft = {
      config = {
        services.minecraft-server = {
          enable = true;
          eula = true;
          declarative = true;

          package = pkgs.local.papermc;
          inherit (cfg) dataDir;
          openFirewall = true;

          jvmOpts = "-Xms8G -Xmx8G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true";

          serverProperties = {
            server-port = cfg.containerPort;
            white-list = true;
            motd = "Smol server";
          };

          whitelist = {
            "AzaharPetal" = "24cae93f-e7c5-4ee1-bfc3-a375096fd436";
            "Javier_L_S" = "de6c5b03-4368-4317-9f88-f9a01a53be3e";
          };
        };

        systemd = {
          sockets.minecraft-server.socketConfig = {
            SocketUser = lib.mkForce user.name;
            SocketGroup = lib.mkForce user.group;
          };

          services.minecraft-server.serviceConfig = {
            User = lib.mkForce user.name;
          };
        };

        # Avoids change of dataDir owner
        users.users.minecraft = lib.mkForce {
          description = "Minecraft server service user";
          isSystemUser = true;
          group = "minecraft";
        };
      };
    };
  })
]
