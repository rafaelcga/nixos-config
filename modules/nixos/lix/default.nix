{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.lix;
  version = "latest";
in
{
  options.modules.nixos.lix = {
    enable = lib.mkEnableOption "lix configuration";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        inherit (prev.lixPackageSets.${version})
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          colmena
          ;
      })
    ];

    nix.package = lib.mkForce pkgs.lixPackageSets.${version}.lix;
  };
}
