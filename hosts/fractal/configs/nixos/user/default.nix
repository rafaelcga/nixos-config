{ pkgs, userName, ... }:
{
  users.users.${userName} = {
    description = "Rafa Giménez";
    shell = pkgs.fish;
    # TODO: password
  };
}
