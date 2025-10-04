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
  };
}
