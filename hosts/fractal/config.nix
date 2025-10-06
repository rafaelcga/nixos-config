{ ... }:
{
  imports = [
    ../../modules/nixos
    ./configs/nixos
    ./hardware-configuration.nix
  ];

  modules.nixos = {
    boot = {
      enable = true;
      loader = "limine";
    };
    i18n.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      vendors = [
        "amd"
        "nvidia"
      ];
    };
    time.enable = true;
    networking.enable = true;
    nix.enable = true;
    zram.enable = true;
    catppuccin.enable = true;
    desktop = {
      enable = true;
      environment = "gnome";
    };
  };
}
