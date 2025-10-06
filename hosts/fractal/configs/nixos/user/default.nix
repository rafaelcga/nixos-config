{ pkgs, userName, ... }:
{
  programs.fish.enable = true;
  users.users.${userName} = {
    description = "Rafa Giménez";
    shell = pkgs.fish;
    # TODO: password
  };
}
