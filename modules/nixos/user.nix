{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.user;
in
{
  options.modules.nixos.user = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "User name";
    };
    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fish;
      description = "User login shell";
    };
  };

  config = {
    modules.nixos.user = { inherit (config.users.users.${cfg.name}) home group; };

    programs.${cfg.shell.pname}.enable = true;
    environment.shells = [ cfg.shell ];

    users.users.${cfg.name} = {
      inherit (cfg) shell;
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.user_password.path;
      extraGroups = [ "wheel" ];
    };
  };
}
