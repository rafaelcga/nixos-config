{
  # nixConfig = {
  #   extra-substituters = [
  #     "https://chaotic-nyx.cachix.org"
  #   ];
  #   extra-trusted-public-keys = [
  #     "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
  #   ];
  # };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
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
        # chaotic.nixosModules.default
        sops-nix.nixosModules.sops
        catppuccin.nixosModules.catppuccin
      ];
      homeManagerModules = with inputs; [
        # chaotic.homeManagerModules.default
        sops-nix.homeManagerModules.sops
        catppuccin.homeModules.catppuccin
        plasma-manager.homeModules.plasma-manager
      ];
    in
    {
      # Set default formatter for `nix fmt`
      formatter.${system} = pkgs.nixfmt-tree;
      nixosConfigurations = (
        lib.local.mkSystem {
          inherit stateVersion nixosModules homeManagerModules;
          hostName = "fractal";
          userName = "rafael";
        }
      );
      # // (another)
    };
}
