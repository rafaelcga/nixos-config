{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances.adguardhome or { enable = false; };

  settings = {
    log.enabled = true;
    querylog = {
      enabled = true;
      interval = "24h";
    };
    statistics = {
      enabled = true;
      interval = "24h";
    };
    dns = {
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
in
{
  config = lib.mkIf cfg.enable {
    modules.nixos.containers.instances.adguardhome = {
      containerPort = 3000;
      containerDataDir = "/var/lib/AdGuardHome";
      extraForwardPorts =
        let
          dnsPort = 53;
        in
        [
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
    };

    containers.adguardhome = {
      config = {
        services.adguardhome = {
          enable = true;
          port = cfg.containerPort;
          openFirewall = true;
          inherit settings;
        };
      };
    };
  };
}
