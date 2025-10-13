{
  config,
  pkgs,
  userName,
  ...
}:
{
  environment = {
    variables.EDITOR = "micro";
    systemPackages = [ pkgs.micro ];
    shells = [ pkgs.fish ];
  };
  programs.fish.enable = true;
  users.users.${userName} = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user_password.path;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.fish;
  };
}
