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
    containers.services = {
      servarr = {
        enable = true;
        hostPorts = {
          lidarr = 8004;
          radarr = 8005;
          sonarr = 8006;
          prowlarr = 8007;
        };
      };
    };
  };
}
