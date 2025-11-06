let
  ethernetInterface = "enp1s0";
in
{
  imports = [ ];

  networking.interfaces."${ethernetInterface}".ipv4.addresses = [
    {
      address = "192.168.1.2";
      prefixLength = 24;
    }
  ];

  modules.nixos = {
    # System
    zram.enable = true;
    ssh.enable = true;
    # Hardware
    graphics = {
      enable = true;
      vendors = [ "intel" ];
    };
    # External
    disko.disks = {
      main = {
        device = "/dev/disk/by-id/nvme-CT500P3PSSD8_24234937AA27";
        type = "boot-ext4";
      };
      media = {
        device = "/dev/disk/by-id/nvme-KIOXIA-EXCERIA_PLUS_G3_SSD_XEHKF0CNZ0EA";
        destroy = false;
        mountpoint = "/mnt/media";
        type = "mnt-media-ext4";
      };
    };
    # Services
    caddy.enable = true;
    crowdsec.enable = true;
    # Containers
    containers = {
      externalInterface = ethernetInterface;
      hostAddress = "172.22.0.1";
      hostAddress6 = "fc00::1";
      # WebUI port range 8000-8999
      instances = {
        adguardhome = {
          enable = true;
          localAddress = "172.22.0.2";
          localAddress6 = "fc00::2";
          webPort = 8000;
        };
        ddns-updater = {
          enable = true;
          localAddress = "172.22.0.3";
          localAddress6 = "fc00::3";
          webPort = 8001;
        };
        jellyfin = {
          enable = true;
          localAddress = "172.22.0.4";
          localAddress6 = "fc00::4";
          gpuPassthrough = true;
          bindMounts = {
            "/media" = {
              hostPath = "/mnt/media";
              isReadOnly = true;
            };
          };
        };
      };
    };
  };
}
