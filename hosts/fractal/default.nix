{
  modules.nixos = {
    # System
    fonts.enable = true;
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
    printing = {
      enable = true;
      vendors = [ "brother" ];
    };
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
    # cosmic.enable = true;
    plasma.enable = true;
    # Theming
    cursor.enable = true;
    papirus.enable = true;
    # Features
    cachyos-settings.enable = true;
    flatpak.enable = true;
    # Apps
    steam = {
      enable = true;
      protonWayland.enable = true;
    };
    uv.enable = true;
  };

  # Native NixOS modules and stand-alone configurations
  hardware.opentabletdriver.enable = true;

  boot.loader.systemd-boot.windows."11" = {
    title = "Windows 11";
    efiDeviceHandle = "FS0";
  };
}
