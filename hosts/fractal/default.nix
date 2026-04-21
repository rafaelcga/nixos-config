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
    flatpak = {
      enable = true;
      packages = [
        "it.mijorus.gearlever"
        "io.ente.auth"
        "com.protonvpn.www"
        "org.telegram.desktop"
        "com.discordapp.Discord"
        "com.spotify.Client"
        "com.vysp3r.ProtonPlus"
        "org.kde.krita"
        "org.kde.haruna"
        "org.gnome.Calendar"
      ];
    };
    # Apps
    steam = {
      enable = true;
      protonWayland.enable = true;
    };
    uv.enable = true;
  };

  # Native NixOS modules and stand-alone configurations
  hardware.opentabletdriver.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  boot.loader.systemd-boot.windows."11" = {
    title = "Windows 11";
    efiDeviceHandle = "FS0";
  };
}
