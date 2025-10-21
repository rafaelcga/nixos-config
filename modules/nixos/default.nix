{ inputs, ... }:
{
  imports = [
    # External modules
    inputs.disko.nixosModules.disko
    ./home-manager.nix

    # Local modules
    ./hardware
    ./system
    ./i18n.nix
    ./sops.nix
    ./user.nix
  ];
}
