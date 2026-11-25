{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.nix-impl;

  substituters = [
    # Lower value means higher priority; default is 40
    "https://cache.nixos.org?priority=10"
    "https://nix-community.cachix.org"
    "https://rafaelcga.cachix.org"
  ];

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

        # `trusted-users` is left at its default, root only: a trusted user can
        # disable signature checks or add caches, which amounts to root
        # without sudo. Only wheel may use the daemon at all
        allowed-users = [
          "root"
          "@wheel"
        ];

        # Used for everyone's builds. Listing them as trusted-substituters too
        # lets non-trusted users explicitly opt into them (e.g. a flake's
        # `nixConfig.extra-substituters`)
        inherit substituters;
        trusted-substituters = substituters;
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

    programs.nh = lib.mkIf (!config.boot.isContainer) {
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
