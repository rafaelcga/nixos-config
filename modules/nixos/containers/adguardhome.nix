{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances.adguardhome or { enable = false; };
  hostDataDir = config.modules.nixos.containers.dataDir;

  dataDir = "/var/lib/AdGuardHome";
  dnsPort = 53;
  containerWebPort = 3000;
in
{
  config = lib.mkIf cfg.enable {
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
      ++ lib.optionals (cfg.webPort != null) [
        {
          containerPort = containerWebPort;
          hostPort = cfg.webPort;
          protocol = "tcp";
        }
      ];

      bindMounts = {
        "${dataDir}" = {
          hostPath = "${hostDataDir}/adguardhome";
          isReadOnly = false;
        };
      };

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
