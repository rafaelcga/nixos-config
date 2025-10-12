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
    };
  };
}
