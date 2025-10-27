{ config, lib, ... }:
let
  cfg = config.modules.nixos.ssh;
in
{
  options.modules.nixos.ssh = {
    enable = lib.mkEnableOption "Enable SSH";
  };

  config = lib.mkIf cfg.enable {
    services = {
      openssh = {
        enable = true;
        settings.PermitRootLogin = "no";
      };

      fail2ban = {
        enable = true;
        maxretry = 5;
        bantime = "24h";
        bantime-increment = {
          enable = true;
          maxtime = "168h"; # Do not ban more than 1 week
        };
      };
    };
  };
}
