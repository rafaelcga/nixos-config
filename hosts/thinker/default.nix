{
  modules.nixos = {
    # System
    fonts.enable = true;
    zram.enable = true;
    # Hardware
    audio = {
      enable = true;
      bufferSize = 512; # Less CPU intensive
    };
    graphics = {
      enable = true;
      vendors = [ "amd" ];
    };
    printing.enable = true;
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
    # Features
    cachyos-settings.enable = true;
    flatpak.enable = true;
  };

  # Native NixOS modules and stand-alone configurations
  hardware.opentabletdriver.enable = true;
}
