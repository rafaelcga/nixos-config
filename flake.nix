{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
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
    { ... }@inputs:
    let
      lib = import ./lib/extended-lib.nix inputs;
      pkgs = import inputs.nixpkgs { inherit system; };
      system = "x86_64-linux";
      stateVersion = "25.11";
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
