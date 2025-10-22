{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./home-manager.nix
    ./sops.nix
  ];
}
