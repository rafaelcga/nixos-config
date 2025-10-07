{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.lix;
in
{
  options.modules.nixos.lix = {
    enable = lib.mkEnableOption "lix configuration";
    version = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "latest"
        "git"
      ];
      default = "latest";
      description = "Lix version (stable, latest, git)";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        inherit (prev.lixPackageSets.${cfg.version})
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena
          ;
      })
    ];

    nix.package = lib.mkForce pkgs.lixPackageSets.${cfg.version}.lix;
  };
}
