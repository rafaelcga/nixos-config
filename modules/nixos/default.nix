{ inputs, ... }:
{
  imports = [
    # External modules
    inputs.disko.nixosModules.disko
    ./home-manager.nix
    ./sops.nix

    # Local modules
    ./hardware
    ./system
    ./i18n.nix
    ./user.nix
  ];
}
