{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./home-manager.nix

    ./hardware
    ./system

    ./i18n.nix
    ./user.nix
    ./sops.nix
  ];
}
