{ pkgs, userName, ... }:
{
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
