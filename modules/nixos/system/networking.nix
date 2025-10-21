{
  config,
  lib,
  ...
}:
let
  inherit (config.modules.nixos) user;
  cfg = config.modules.nixos.networking;
in
{
  options.modules.nixos.networking = {
    fail2ban.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Whether to enable fail2ban for SSH";
    };
  };

  config = {
    users.users.${user.name}.extraGroups = [ "networkmanager" ];

    networking = {
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
