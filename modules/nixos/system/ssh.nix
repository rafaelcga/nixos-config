{ config, lib, ... }:
let
  cfg = config.modules.nixos.ssh;
in
{
  options.modules.nixos.ssh = {
    enable = lib.mkEnableOption "Enable SSH";
    fail2ban.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Whether to enable fail2ban for SSH";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      openssh = {
        enable = true;
        settings.PermitRootLogin = "no";
      };

      fail2ban = lib.mkIf cfg.fail2ban.enable {
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
