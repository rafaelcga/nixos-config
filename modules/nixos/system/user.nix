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
  user = config.users.users.${userName};
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

    # A `mkpasswd` hash. With mutable users (the default) NixOS only applies it
    # when the account is created: on existing hosts, change it with `passwd`.
    # Root-only: just the activation script needs it
    sops.secrets."passwords/user" = {
      sopsFile = config.modules.nixos.sops-nix.commonSopsFile;
      neededForUsers = true;
    };

    users.users.${userName} = lib.mkMerge [
      {
        shell = pkgs.${cfg.shell};
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."passwords/user".path;
        extraGroups = [ "wheel" ];
      }
      flakeMeta.users.${userName}
    ];

    # Only wheel can even run sudo (smaller attack surface for sudo bugs)
    security.sudo.execWheelOnly = true;

    # XDG Base Directory
    environment.sessionVariables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };
  };
}
