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

    defaultGateway = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.1";
      description = "Default gateway for the default network interface";
    };
  };

  config = lib.mkMerge [
    {
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

        firewall.enable = true;
        nftables.enable = true;
      };

      services = {
        resolved = {
          enable = true;
          dnssec = "allow-downgrade";
          domains = [ "~." ];
          # Quad9 as fallback
          fallbackDns = [
            "9.9.9.9"
            "149.112.112.112"
            "2620:fe::fe"
            "2620:fe::9"
          ];
          dnsovertls = "true";
        };

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
            maxtime = "168h";
          };
        };
      };

      systemd.network.wait-online.enable =
        config.systemd.network.enable && !config.networking.networkmanager.enable;

      users.users.${userName}.extraGroups = [ "networkmanager" ];
    }
    (lib.mkIf (cfg.staticIp != null) {
      networking = {
        interfaces."${cfg.defaultInterface}".ipv4.addresses = [
          {
            address = cfg.staticIp;
            prefixLength = 24;
          }
        ];

        defaultGateway = {
          address = cfg.defaultGateway;
          interface = cfg.defaultInterface;
        };
      };
    })
  ];
}
