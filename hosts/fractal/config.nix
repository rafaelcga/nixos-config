{ ... }:
{
  imports = [
    ../../modules/common
    ../../modules/nixos
    ./configs/nixos
    # ./config-disk.nix
    ./hardware-configuration.nix
  ];

  modules = {
    common = {
      theme.enable = true;
    };
    nixos = {
      # Core
      boot = {
        enable = true;
        loader = "limine";
      };
      networking.enable = true;
      nix.enable = true;
      lix.enable = true;
      zram.enable = true;
      i18n.enable = true;
      time.enable = true;
      cachy.enable = true;
      keyboard.enable = true;
      audio.enable = true;
      graphics = {
        enable = true;
        enable32Bit = true;
        vendors = [
          "amd"
          "nvidia"
        ];
      };
      # Desktop environment
      desktop.plasma.enable = true;
      # Programs
      flatpak.enable = true;
      steam.enable = true;
      qemu.enable = true;
    };
  };
}
