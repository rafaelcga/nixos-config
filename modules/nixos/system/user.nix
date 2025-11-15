{
  config,
  lib,
  pkgs,
  flakeMeta,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.user;
in
{
  options.modules.nixos.user = {
    shell = lib.mkOption {
      type = lib.types.enum [
        "bash"
        "fish"
      ];
      default = "fish";
      description = "User login shell";
    };
  };

  config = {
    programs.${cfg.shell}.enable = true;
    environment.shells = [ pkgs.${cfg.shell} ];

    sops.secrets."passwords/user".neededForUsers = true;

    users.users.${userName} = lib.mkMerge [
      {
        shell = pkgs.${cfg.shell};
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."passwords/user".path;
        extraGroups = [ "wheel" ];
      }
      flakeMeta.users.${userName}
    ];

    # XDG Base Directory
    environment.sessionVariables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };
  };
}
