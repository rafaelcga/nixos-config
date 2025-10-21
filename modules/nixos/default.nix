{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko

    ./hardware
    ./system

    # ./home-manager.nix
    ./i18n.nix
    ./user.nix
    ./sops.nix
  ];
}
