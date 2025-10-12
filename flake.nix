{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

  };

  outputs =
    { ... }@inputs:
    let
      lib = import ./lib/extended-lib.nix inputs;
      pkgs = import inputs.nixpkgs { inherit system; };
      system = "x86_64-linux";
      stateVersion = "25.11";

      nixosModules = with inputs; [
        home-manager.nixosModules.home-manager
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        catppuccin.nixosModules.catppuccin
      ];
      homeManagerModules = with inputs; [
        sops-nix.homeManagerModules.sops
        catppuccin.homeModules.catppuccin
        plasma-manager.homeModules.plasma-manager
      ];
    in
    {
      # Set default formatter for `nix fmt`
      formatter.${system} = pkgs.nixfmt-tree;
      nixosConfigurations =
        (lib.local.mkSystem {
          inherit stateVersion nixosModules homeManagerModules;
          hostName = "fractal";
          userName = "rafael";
        })
        // (lib.local.mkSystem {
          inherit stateVersion nixosModules homeManagerModules;
          hostName = "beelink";
          userName = "seal";
        });
      # // (another)
    };
}
