{
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.networking;
in
{
  options.modules.nixos.networking = {
    staticIp = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Static IPv4 address for the system";
    };

    defaultInterface = lib.mkOption {
      type = lib.types.str;
      default = "wlan0";
      description = "Default network interface";
    };
  };

  config = {
    networking = {
      networkmanager = {
        enable = true;
        dns = "systemd-resolved";
        wifi.backend = "iwd";
      };

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

      interfaces."${cfg.defaultInterface}" = {
        ipv4.addresses = lib.optionals (cfg.staticIp != null) [
          {
            address = cfg.staticIp;
            prefixLength = 24;
          }
        ];
      };

      nftables.enable = true;
      firewall.enable = true;
    };

    services.resolved = {
      enable = true;
      dnssec = "allow-downgrade";
      # Quad9 as fallback
      fallbackDns = [
        "9.9.9.9"
        "149.112.112.112"
        "2620:fe::fe"
        "2620:fe::9"
      ];
    };

    users.users.${userName}.extraGroups = [ "networkmanager" ];
  };
}
