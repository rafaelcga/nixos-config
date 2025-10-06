{ userName, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
  };
}
