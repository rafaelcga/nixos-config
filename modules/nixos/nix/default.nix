{
  config,
  lib,
  pkgs,
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
        trusted-users = [
          "root"
          "@wheel"
        ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      optimise.automatic = true;
      channel.enable = false;
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };
    nixpkgs.config.allowUnfree = true;
  };
}
