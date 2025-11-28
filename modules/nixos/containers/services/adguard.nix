{
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.adguard;

  dnsPort = 53;
  disableStubListener = ''
    DNSStubListener=no
  '';
in
lib.mkMerge [
  {
    modules.nixos.containers.services.adguard = {
      containerPort = 3000;
      containerDataDir = "/var/lib/AdGuardHome";
    };
  }
  (lib.mkIf cfg.enable {
    services.resolved = lib.mkIf (config.services.resolved.enable) {
      extraConfig = disableStubListener;
    };

    # networking.firewall = rec {
    #   allowedTCPPorts = [ dnsPort ];
    #   allowedUDPPorts = allowedTCPPorts;
    # };

    containers.adguard = {
      forwardPorts =
        let
          mkDnsPort = protocol: rec {
            containerPort = dnsPort;
            hostPort = containerPort;
            inherit protocol;
          };
        in
        lib.map mkDnsPort [
          "tcp"
          "udp"
        ];

      config =
        { config, pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [
            dig
            tcpdump
          ];

          services.resolved = lib.mkIf (config.services.resolved.enable) {
            extraConfig = disableStubListener;
          };

          systemd.services.adguardhome = {
            serviceConfig = {
              DynamicUser = lib.mkForce false;
            };
          };

          services.adguardhome = {
            enable = true;
            port = cfg.containerPort;
            openFirewall = true;

            settings = {
              log.enabled = true;
              users = [
                {
                  name = userName;
                  password = "$2b$12$kZpm0P3wFyidgKBwribsO.Y/ouoHppUvbJ3ifqaQRX8J8mWB1aDMC";
                }
              ];
              querylog = {
                enabled = true;
                interval = "24h";
              };
              statistics = {
                enabled = true;
                interval = "24h";
              };
              dns = {
                allowed_clients = [
                  "172.16.0.0/12"
                  "192.168.0.0/16"
                ];
                upstream_dns = [
                  "https://dns.quad9.net/dns-query"
                  "tls://dns.quad9.net"
                ];
                bootstrap_dns = [
                  "9.9.9.9"
                  "149.112.112.112"
                  "2620:fe::fe"
                  "2620:fe::fe:9"
                ];
                ratelimit = 0;
                edns_client_subnet.enabled = false;
                enable_dnssec = true;
                blocking_mode = "default";
              };
              filtering.filters_update_interval = 1;
              filters = [
                {
                  enabled = true;
                  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
                  name = "AdGuard DNS filter";
                  id = 1;
                }
                {
                  enabled = true;
                  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_55.txt";
                  name = "HaGeZi's Badware Hoster Blocklist";
                  id = 1741636457;
                }
                {
                  enabled = true;
                  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_47.txt";
                  name = "HaGeZi's Gambling Blocklist";
                  id = 1741636458;
                }
                {
                  enabled = true;
                  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt";
                  name = "HaGeZi's Pro++ Blocklist";
                  id = 1741636459;
                }
                {
                  enabled = true;
                  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt";
                  name = "HaGeZi's Threat Intelligence Feeds";
                  id = 1741636460;
                }
                {
                  enabled = true;
                  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt";
                  name = "Dandelion Sprout's Anti-Malware List";
                  id = 1741743309;
                }
                {
                  enabled = true;
                  url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt";
                  name = "uBlock₀ filters – Badware risks";
                  id = 1741743310;
                }
              ];
            };
          };
        };
    };
  })
]
