{
  modules.nixos = {
    # System
    fonts.enable = true;
    # Hardware
    audio = {
      enable = true;
      bufferSize = 256; # Less CPU intensive
    };
    graphics = {
      enable = true;
      vendors = [ "amd" ];
    };
    printing = {
      enable = true;
      vendors = [
        "brother"
        "hp"
      ];
    };
    # External modules
    disko.disks = {
      main = {
        device = "/dev/disk/by-id/nvme-SKHynix_HFS512GDE9X081N_CJ0CN78481110CO6V";
        format = "ext4";
        isBootable = true;
      };
    };
    catppuccin.enable = true;
    # Desktop
    cosmic.enable = true;
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
  };

  # Native NixOS modules and stand-alone configurations
  hardware.opentabletdriver.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
