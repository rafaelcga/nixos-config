{ pkgs, ... }:
{
  programs = {
    git = {
      enable = true;
      userName = "rafaelcga";
      userEmail = "68070715+rafaelcga@users.noreply.github.com";
      extraConfig = {
        pull.rebase = true;
      };
      difftastic.enable = true;
    };
    fish = {
      enable = true;
      shellInit = "set -U fish_greeting";
    };
    atuin = {
      enable = true;
      enableFishIntegration = true;
    };
    gh.enable = true;
    btop.enable = true;
    micro.enable = true;
    fastfetch.enable = true;
  };
  home.packages = with pkgs; [
    fzf
    age
    tree
    sops
  ];
}
