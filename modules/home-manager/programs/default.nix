{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.programs;
in
{
  options.modules.home-manager.programs = {
    enable = lib.mkEnableOption "Default suite of programs";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
        # TODO: git identity
        difftastic.enable = true;
      };
      nh = {
        enable = true;
        flake = "$HOME/nixos-config";
      };
      fastfetch.enable = true;
    };
    home.packages = with pkgs; [
      fzf
      tree
      btop
    ];
  };
}
