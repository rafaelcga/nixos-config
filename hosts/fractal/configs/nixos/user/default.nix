{ userName, ... }:
{
  users.users.${userName} = {
    description = "Rafa Giménez";
    # TODO: password
  };
}
