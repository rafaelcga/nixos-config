{
  config,
  lib,
  hostName,
  ...
}:
let
  cfg = config.modules.nixos.networking;
in
{
  options.modules.nixos.networking = {
    enable = lib.mkEnableOption "networking configuration";
    fail2ban.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Whether to enable fail2ban for SSH";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      inherit hostName;
      wireless.iwd = {
        enable = true;
        settings = {
          Network = {
            EnableIPv6 = true;
          };
          Settings = {
            AutoConnect = true;
          };
        };
      };
      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
      };
      nftables.enable = true;
      firewall.enable = true;
    };

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
