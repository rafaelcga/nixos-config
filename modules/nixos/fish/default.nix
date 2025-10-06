{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.fish;
in
{
  options.modules.nixos.fish = {
    enable = lib.mkEnableOption "fish shell configuration";
    makeDefault = lib.mkEnableOption "Use fish as user shell";
  };

  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
    users.users.${userName}.shell = lib.mkIf cfg.makeDefault pkgs.fish;
  };
}
