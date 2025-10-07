{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      catppuccin,
      ...
    }@inputs:
    let
      lib = import ./lib/extended-lib.nix inputs;

      system = "x86_64-linux";
      stateVersion = "25.11";
      hostName = "fractal";
      userName = "rafael";
      specialArgs = {
        inherit
          lib
          inputs
          hostName
          userName
          ;
      };

      pkgs = import nixpkgs { inherit system; };
    in
    {
      inherit lib;
      # Set default formatter for `nix fmt`
      formatter.${system} = pkgs.nixfmt-tree;
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          ./hosts/${hostName}/config.nix
          home-manager.nixosModules.home-manager
          catppuccin.nixosModules.catppuccin
          sops-nix.nixosModules.sops
          ./secrets
          {
            system = { inherit stateVersion; };
            home-manager = {
              backupFileExtension = "bak";
              extraSpecialArgs = specialArgs;
              users.${userName} = {
                imports = [
                  catppuccin.homeModules.catppuccin
                  ./hosts/${hostName}/config-home.nix
                  ./secrets
                ];
                home = { inherit stateVersion; };
              };
              sharedModules = [
                sops-nix.homeManagerModules.sops
              ];
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
        ];
      };
    };
}
