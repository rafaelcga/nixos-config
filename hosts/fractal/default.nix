{ config, lib, ... }:
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  modules.nixos = {
    # System
    boot.loader = "limine";
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
    # External modules
    catppuccin.enable = true;
    # Desktop
    plasma.enable = true;
    # Features
    cachyos-settings.enable = true;
    flatpak.enable = true;
    # Apps
    steam.enable = true;
    virt-manager.enable = true;
  };

  environment.sessionVariables = {
    GSK_RENDERER = "gl"; # fixes graphical flatpak bug under Wayland
    GDK_SCALE = "1.25"; # sets XWayland render scale
    __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # NVIDIA GPU cache
    MESA_SHADER_CACHE_MAX_SIZE = "12G"; # AMD GPU cache
  };

  # Windows Boot Drive
  boot.loader.limine.extraEntries = lib.mkIf config.boot.loader.limine.enable ''
    /Windows
        protocol: efi
        path: uuid(23f2eb9d-b5be-49bb-83f9-b486a3bcc7a3):/EFI/Microsoft/Boot/bootmgfw.efi
  '';
}
