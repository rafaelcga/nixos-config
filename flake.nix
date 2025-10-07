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
      pkgs = import nixpkgs { inherit system; };
    in
    {
      # Set default formatter for `nix fmt`
      formatter.${system} = pkgs.nixfmt-tree;
      nixosConfigurations = (
        lib.local.mkSystem {
          inherit inputs stateVersion;
          hostName = "fractal";
          userName = "rafael";
        }
      );
      # // (another)
    };
}
