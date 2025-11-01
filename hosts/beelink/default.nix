{
  imports = [ ];

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
    disko.disks = [
      {
        name = "main";
        device = "/dev/disk/by-id/nvme-CT500P3PSSD8_24234937AA27";
        type = "boot-ext4";
      }
    ];
    # Services
    caddy.enable = true;
    crowdsec.enable = true;
    # Containers
    containers = {
      externalInterface = "enp1s0";
      hostAddress = "172.22.0.1";
      hostAddress6 = "fc00::1";
      # Enabled containers
      instances = {
        jellyfin = {
          enable = true;
          localAddress = "172.22.0.2";
          localAddress6 = "fc00::2";
        };
      };
    };
  };
}
