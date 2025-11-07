{ config, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

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
    virt-manager.enable = true;
    # Containers
    containers = {
      externalInterface = "enp1s0";
      hostAddress = "172.22.0.1";
      hostAddress6 = "fc00::1";
      # WebUI port range 8000-8999
      instances = {
        adguardhome = {
          enable = true;
          localAddress = "172.22.0.2";
          localAddress6 = "fc00::2";
          hostPort = 8000;
        };
        ddns-updater = {
          enable = true;
          localAddress = "172.22.0.3";
          localAddress6 = "fc00::3";
          hostPort = 8001;
        };
        jellyfin = {
          enable = true;
          localAddress = "172.22.0.4";
          localAddress6 = "fc00::4";
          hostPort = 8002;
          gpuPassthrough = true;
          bindMounts = {
            "/media" = {
              hostPath = "/mnt/media";
              isReadOnly = true;
            };
          };
        };
        servarr = {
          enable = true;
          localAddress = "172.22.0.5";
          localAddress6 = "fc00::5";
          hostPorts = {
            lidarr = 8003;
            radarr = 8004;
            sonarr = 8005;
            prowlarr = 8006;
          };
        };
      };
    };
  };

  environment.sessionVariables.GDK_SCALE = "1.25"; # sets XWayland render scale

  # Windows Boot Drive
  boot.loader.limine.extraEntries = lib.mkIf config.boot.loader.limine.enable ''
    /Windows
        protocol: efi
        path: uuid(23f2eb9d-b5be-49bb-83f9-b486a3bcc7a3):/EFI/Microsoft/Boot/bootmgfw.efi
  '';
}
