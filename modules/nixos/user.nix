{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.user;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.modules.nixos.user = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "User name";
    };
    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fish;
      description = "Login shell to use for user";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.shells = [ cfg.shell ];
    programs."${cfg.shell.pname}".enable = true;
    users.users.${cfg.name} = {
      inherit (cfg) shell;
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.user_password.path;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };
}
