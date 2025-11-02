{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.nix-impl;

  packages = with pkgs; {
    "nix" = nixVersions.${cfg.version};
    "lix" = lixPackageSets.${cfg.version}.lix;
  };
in
{
  options.modules.nixos.nix-impl = {
    implementation = lib.mkOption {
      type = lib.types.enum [
        "nix"
        "lix"
      ];
      default = "lix";
      description = "Nix package manager implementation to use";
    };

    version = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "latest"
        "git"
      ];
      default = "latest";
      description = "Package version (stable, latest, git)";
    };
  };

  config = {
    nix = {
      package = packages.${cfg.implementation};
      settings = {
        auto-optimise-store = true; # Optimizes store after every build

        experimental-features = [
          "nix-command"
          "flakes"
        ];

        trusted-users = [
          "root"
          "@wheel"
        ];

        substituters = [
          # Lower value means higher priority; default is 40
          "https://cache.nixos.org?priority=10"
          "https://nix-community.cachix.org"
          "https://rafaelcga.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "rafaelcga.cachix.org-1:rwBDDlTDx0rxoecuMjIx6yxPQU+0nc49Y7d04OaklG0="
        ];
      };
      # Uses programs.nh.clean as garbage collector instead
      # gc = {
      #   automatic = true;
      #   dates = "weekly";
      #   options = "--delete-older-than 7d";
      # };
    };

    programs.nh = {
      enable = true;
      clean = {
        enable = true; # nh clean as a service
        extraArgs = "--keep-since 4d --keep 3";
      };
    };

    nixpkgs.overlays = lib.mkIf (cfg.implementation == "lix") [
      (final: prev: {
        inherit (prev.lixPackageSets.${cfg.version})
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena
          ;
      })
    ];
  };
}
