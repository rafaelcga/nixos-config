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
      hostName = "fractal";
      userName = "rafael";
      pkgs = import nixpkgs { inherit system; };
      specialArgs = {
        inherit
          inputs
          stateVersion
          hostName
          userName
          ;
      };
    in
    {
      # Set default formatter for `nix fmt`
      formatter.${system} = pkgs.nixfmt-tree;
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/${hostName}/config.nix
          ./hosts/${hostName}/configuration.nix
          home-manager.nixosModules.home-manager
          {
            system = { inherit stateVersion; };
            home-manager = {
              backupFileExtension = "bak";
              extraSpecialArgs = specialArgs;
              users.${userName} = {
                imports = [ ./hosts/${hostName}/config-home.nix ];
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
