{ config, lib, ... }:
let
  inherit (config.modules.nixos) user;
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

      interfaces."${config.modules.nixos.networking.defaultInterface}" = {
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

    users.users.${user.name}.extraGroups = [ "networkmanager" ];
  };
}
