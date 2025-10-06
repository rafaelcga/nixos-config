{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.bash;
in
{
  options.modules.nixos.bash = {
    enable = lib.mkEnableOption "bash shell configuration";
    makeDefault = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Use bash as user shell";
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      bash = {
        enable = true;
        shellInit = ''
          echo 'eval "$(atuin init bash)"'
        '';
        atuin.enable = true;
      };
    };
    environment.shells = [ pkgs.bash ];
    users.users.${userName}.shell = lib.mkIf cfg.makeDefault pkgs.bash;
  };
}
