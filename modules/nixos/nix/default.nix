{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.nix;
in
{
  options.modules.nixos.nix = {
    enable = lib.mkEnableOption "nix package manager configuration";
  };

  config = lib.mkIf cfg.enable {
    nix = {
      package = pkgs.nixVersions.latest;
      settings = {
        auto-optimise-store = true; # Optimizes store after every build
        trusted-users = [
          "root"
          "@wheel"
        ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };
    programs.nh = {
      enable = true;
      clean = {
        enable = true; # nh clean as a service
        extraArgs = "--keep-since 4d --keep 3";
      };
      flake = "/home/${userName}/nixos-config"; # path w.r.t. $HOME
    };
    nixpkgs.config.allowUnfree = true;
  };
}
