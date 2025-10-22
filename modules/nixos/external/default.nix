{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./catppuccin.nix
    ./home-manager.nix
    ./sops.nix
  ];
}
