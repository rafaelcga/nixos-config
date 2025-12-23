{
  description = "The horrors are never ending, yet I remain silly";

  outputs =
    inputs@{ flake-parts, ... }:
    let
      flakeMeta = {
        users = {
          rafael = {
            description = "Rafa Giménez";
          };
        };

        hosts = {
          fractal = {
            user = "rafael";
            system = "x86_64-linux";
          };
          beelink = {
            user = "rafael";
            system = "x86_64-linux";
          };
          thinker = {
            user = "rafael";
            system = "x86_64-linux";
          };
        };

        stateVersion = "26.05";
      };
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs = { inherit flakeMeta; };
      }
      {
        imports = [ ./parts ];
        systems = [ "x86_64-linux" ];
      };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

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
  };
}
