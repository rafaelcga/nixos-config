{ ... }:
{
  imports = [
    ../../modules/common
    ../../modules/nixos
    ./configs/nixos
    ./hardware-configuration.nix
  ];

  modules = {
    nixos = {
      # Core
      boot.enable = true;
      networking.enable = true;
      nix.enable = true;
      lix.enable = true;
      zram.enable = true;
      i18n.enable = true;
      time.enable = true;
      keyboard.enable = true;
      graphics = {
        enable = true;
        vendors = [ "intel" ];
      };
    };
  };
}
