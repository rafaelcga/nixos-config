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
    lix.enable = true;
    zram.enable = true;
    desktop.cosmic.enable = true;
    flatpak.enable = true;
    audio.enable = true;
    theme.enable = true;
    fish.enable = true;
    keyboard.enable = true;
    steam.enable = true;
    cachy.enable = true;
  };
}
