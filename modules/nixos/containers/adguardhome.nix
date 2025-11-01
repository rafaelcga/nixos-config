{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances;

  dnsPort = 53;
  containerWebPort = 3000;
in
{
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
      ]
      ++ lib.optionals (cfg.adguardhome.webPort != null) [
        {
          containerPort = containerWebPort;
          hostPort = cfg.adguardhome.webPort;
          protocol = "tcp";
        }
      ];

      config = {
        services.adguardhome = {
          enable = true;
          port = containerWebPort;
          openFirewall = true;
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ dnsPort ];
      allowedUDPPorts = [ dnsPort ];
    };
  };
}
