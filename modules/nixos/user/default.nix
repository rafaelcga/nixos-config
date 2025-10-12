{ pkgs, userName, ... }:
{
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.fish;
  };
}
