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
      stateVersion = "25.11";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      # Set default formatter for `nix fmt`
      formatter.${system} = pkgs.nixfmt-tree;
      nixosConfigurations.fractal = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/fractal/config.nix
          ./hosts/fractal/configuration.nix
          home-manager.nixosModules.home-manager
          {
            system = { inherit stateVersion; };
            home-manager = {
              backupFileExtension = "bak";
              users.rafael = {
                imports = [ ];
                home = { inherit stateVersion; };
              };
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
        ];
      };
    };
}
