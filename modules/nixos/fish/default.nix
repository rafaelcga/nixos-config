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
    makeDefault = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Use fish as user shell";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
    environment.shells = [ pkgs.fish ];
    users.users.${userName}.shell = lib.mkIf cfg.makeDefault pkgs.fish;
  };
}
