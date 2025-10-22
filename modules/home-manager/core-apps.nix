{ pkgs, osConfig, ... }:
let
  usesNvidia = builtins.elem "nvidia" osConfig.modules.nixos.graphics.vendors;
in
{
  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          name = "rafaelcga";
          email = "68070715+rafaelcga@users.noreply.github.com";
        };
        pull.rebase = true;
      };
    };
    difftastic.git.enable = true;

    fish = {
      enable = true;
      shellInit = "set -U fish_greeting";
    };

    atuin = {
      enable = true;
      enableFishIntegration = true;
    };

    btop = {
      enable = true;
      package = if usesNvidia then pkgs.btop-cuda else pkgs.btop;
    };

    gh.enable = true;
    micro.enable = true;
    fastfetch.enable = true;
  };

  home.packages = with pkgs; [
    fzf
    tree
  ];
}
