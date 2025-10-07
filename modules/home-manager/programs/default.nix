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
        userName = "rafaelcga";
        userEmail = "68070715+rafaelcga@users.noreply.github.com";
        extraConfig = {
          pull.rebase = false;
        };
        difftastic.enable = true;
      };
      gh.enable = true;
      nh.enable = true;
      atuin.enable = true;
      micro.enable = true;
      fastfetch.enable = true;
    };
    home = {
      packages = with pkgs; [
        fzf
        age
        tree
        btop
        sops
      ];
      sessionVariables = lib.mkForce {
        EDITOR = "micro";
        NH_FLAKE = "${config.home.homeDirectory}/nixos-config"; # path w.r.t. $HOME
      };
    };
  };
}
