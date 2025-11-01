{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances;

  dnsPort = 53;
  containerWebPort = config.services.adguardhome.port;
in
{
  options.modules.nixos.containers.instances.adguardhome = {
    webPort = lib.mkOption {
      type = lib.types.ints.unsigned;
      description = "AdguardHome WebUI in the host";
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
        {
          containerPort = containerWebPort;
          hostPort = cfg.webPort;
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
      allowedTCPPorts = [
        dnsPort
        cfg.webPort
      ];
      allowedUDPPorts = [
        dnsPort
      ];
    };
  };
}
