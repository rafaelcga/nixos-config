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
    makeDefault = lib.mkEnableOption "Use bash as user shell";
  };

  config = lib.mkIf cfg.enable {
    programs.bash.enable = true;
    environment.shells = [ pkgs.bash ];
    users.users.${userName}.shell = lib.mkIf cfg.makeDefault pkgs.bash;
  };
}
