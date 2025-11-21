{
  modules.nixos = {
    # System
    networking = {
      staticIp = "192.168.1.2";
      defaultInterface = "enp1s0";
    };
    ssh.enable = true;
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
    containers = {
      hostAddress = "172.22.0.1";
      hostAddress6 = "fc00::1";
      # WebUI port range 8000-8999
      instances = {
        homepage = {
          enable = true;
          localAddress = "172.22.0.2";
          localAddress6 = "fc00::2";
          hostPort = 8000;
        };
        adguardhome = {
          enable = true;
          localAddress = "172.22.0.3";
          localAddress6 = "fc00::3";
          hostPort = 8001;
        };
        ddns-updater = {
          enable = true;
          localAddress = "172.22.0.4";
          localAddress6 = "fc00::4";
          hostPort = 8002;
        };
        jellyfin = {
          enable = true;
          localAddress = "172.22.0.5";
          localAddress6 = "fc00::5";
          hostPort = 8003;
          gpuPassthrough = true;
          bindMounts = {
            "/media" = {
              hostPath = "/mnt/media";
              isReadOnly = true;
            };
          };
        };
        servarr = {
          enable = true;
          localAddress = "172.22.0.6";
          localAddress6 = "fc00::6";
          hostPorts = {
            lidarr = 8004;
            radarr = 8005;
            sonarr = 8006;
            prowlarr = 8007;
          };
          bindMounts = {
            "/media" = {
              hostPath = "/mnt/media";
              isReadOnly = false;
            };
          };
        };
        qbittorrent = {
          enable = true;
          localAddress = "172.22.0.7";
          localAddress6 = "fc00::7";
          hostPort = 8008;
        };
      };
    };
  };
}
