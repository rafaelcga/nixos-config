{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    {
      nixosConfigurations.fractal = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/fractal/nixos.nix
          ./hosts/fractal/configuration.nix
        ];
      };
    };
}
