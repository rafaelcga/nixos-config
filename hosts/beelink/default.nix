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
  };
}
