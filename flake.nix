{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      catppuccin,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      stateVersion = "25.11";
      hostName = "fractal";
      userName = "rafael";
      catppuccinTheme = {
        flavor = "frappe";
        accent = "teal";
      };
      pkgs = import nixpkgs { inherit system; };
      specialArgs = {
        inherit
          inputs
          stateVersion
          hostName
          userName
          catppuccinTheme
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
          catppuccin.nixosModules.catppuccin
          {
            system = { inherit stateVersion; };
            home-manager = {
              backupFileExtension = "bak";
              extraSpecialArgs = specialArgs;
              users.${userName} = {
                imports = [
                  catppuccin.homeModules.catppuccin
                  ./hosts/${hostName}/config-home.nix
                ];
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
