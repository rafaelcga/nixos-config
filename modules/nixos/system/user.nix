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

    home = lib.mkOption {
      type = lib.types.str;
      default = config.users.users.${cfg.name}.home;
      description = "User home directory";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = config.users.users.${cfg.name}.group;
      description = "User primary group";
    };

    shell = lib.mkOption {
      type = lib.types.enum [
        "bash"
        "fish"
      ];
      default = "fish";
      description = "User login shell";
    };

    description = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "User's full name";
    };

    sshPrivateKey = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.home}/.ssh/id_ed25519";
      description = "Path to the private SSH key";
    };
  };

  config = {
    programs.${cfg.shell}.enable = true;
    environment.shells = [ pkgs.${cfg.shell} ];

    sops.secrets."passwords/user".neededForUsers = true;

    users.users.${cfg.name} = {
      inherit (cfg) description;
      shell = pkgs.${cfg.shell};
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets."passwords/user".path;
      extraGroups = [ "wheel" ];
    };
  };
}
