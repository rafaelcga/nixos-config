{ config, lib, ... }:
let
  cfg = config.modules.nixos.ssh;
in
{
  options.modules.nixos.ssh = {
    enable = lib.mkEnableOption "Enable SSH";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
    };
  };
}
