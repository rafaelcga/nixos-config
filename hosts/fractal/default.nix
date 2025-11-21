{ config, lib, ... }:
{
  modules.nixos = {
    # System
    fonts.enable = true;
    ssh.enable = true;
    zram.enable = true;
    # Hardware
    audio.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      vendors = [
        "amd"
        "nvidia"
      ];
    };
    printing.enable = true;
    # External modules
    disko.disks = {
      main = {
        device = "/dev/disk/by-id/nvme-KIOXIA-EXCERIA_PLUS_G3_SSD_4EAKF0X9Z0EA";
        format = "ext4";
        isBootable = true;
      };
    };
    catppuccin.enable = true;
    # Desktop
    cosmic.enable = true;
    # Features
    cachyos-settings.enable = true;
    flatpak.enable = true;
    # Apps
    steam.enable = true;
  };

  environment.sessionVariables.GDK_SCALE = "1.25"; # sets XWayland render scale
}
