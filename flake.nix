{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      # Set default formatter for `nix fmt`
      formatter.${system} = pkgs.nixfmt-tree;
      nixosConfigurations.fractal = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/fractal/config.nix
          ./hosts/fractal/configuration.nix
          {
            home-manager.nixosModules.home-manager = {
              backupFileExtension = "bak";
              users.rafael = {
                imports = [ ];
                home.stateVersion = 25.11;
              };
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
        ];
      };
    };
}
