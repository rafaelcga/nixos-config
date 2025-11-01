{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances;

  dnsPort = 53;
in
{
  options.modules.nixos.containers.instances.adguardhome = {
    port = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = config.services.adguardhome.port;
      description = "Web interface port";
    };
  };

  config = lib.mkIf (cfg ? "adguardhome" && cfg.adguardhome.enable) {
    containers.adguardhome = {
      forwardPorts = [
        {
          containerPort = dnsPort;
          hostPort = dnsPort;
          protocol = "tcp";
        }
        {
          containerPort = dnsPort;
          hostPort = dnsPort;
          protocol = "udp";
        }
      ];

      config = {
        services.adguardhome = {
          inherit (cfg.adguardhome) port;
          enable = true;
          openFirewall = true;
        };
      };
    };

    modules.nixos.caddy = lib.mkIf config.modules.nixos.caddy.enable {
      virtualHosts.adguardhome = {
        originHost = cfg.adguardhome.localAddress;
        originPort = cfg.adguardhome.port;
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ dnsPort ];
      allowedUDPPorts = [ dnsPort ];
    };
  };
}
