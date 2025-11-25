{ config, userName, ... }:
{
  modules.nixos = {
    # System
    networking = {
      staticIp = "192.168.1.2";
      defaultInterface = "enp1s0";
    };
    upgrade.enable = true;
    zram.enable = true;
    # Hardware
    graphics = {
      enable = true;
      vendors = [ "intel" ];
    };
    # External
    disko.disks = {
      main = {
        device = "/dev/disk/by-id/nvme-CT500P3PSSD8_24234937AA27";
        format = "ext4";
        isBootable = true;
      };
      media = {
        device = "/dev/disk/by-id/nvme-KIOXIA-EXCERIA_PLUS_G3_SSD_XEHKF0CNZ0EA";
        format = "ext4";
        mountpoint = "/mnt/media";
        destroy = false;
      };
    };
    # Services
    caddy.enable = true;
    crowdsec.enable = true;
    # Containers
    containers.services = {
      homepage = {
        enable = true;
        hostPort = 8000;
      };
      ddns-updater = {
        enable = true;
        hostPort = 8002;
      };
      jellyfin = {
        enable = true;
        hostPort = 8003;
        gpuPassthrough = true;
        bindMounts."/media" = {
          hostPath = "/mnt/media";
          isReadOnly = true;
        };
      };
      servarr = {
        enable = true;
        hostPorts = {
          lidarr = 8004;
          radarr = 8005;
          sonarr = 8006;
          prowlarr = 8007;
        };
        bindMounts."/media" = {
          hostPath = "/mnt/media";
          isReadOnly = false;
        };
      };
      qbittorrent = {
        enable = true;
        hostPort = 8008;
      };
    };
  };

  systemd.tmpfiles.settings = {
    "10-media-directory" = {
      "/mnt/media" = {
        d = {
          user = userName;
          inherit (config.users.users.${userName}) group;
          mode = "2775";
        };
        "A+".argument = "default:group::rwx";
      };
    };
  };
}
