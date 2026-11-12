{
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.adguard;
  inherit (config.modules.nixos.containers) user;

  bootstrapDns = [
    "9.9.9.9"
    "149.112.112.112"
    "2620:fe::fe"
    "2620:fe::9"
  ];

  dnsPort = 53;
  dnsServers = [ cfg.address ] ++ bootstrapDns;

  # Replaced at service start with the bcrypt hash from sops
  passwordSecret = config.sops.secrets."adguard/password_hash".path;
  passwordPlaceholder = "@ADGUARD_PASSWORD_HASH@";
in
lib.mkMerge [
  {
    modules.nixos.containers.services.adguard = {
      uid = 2;
      containerPort = 3000;
      dataDir = "/var/lib/AdGuardHome";
      # Stopping it would take down DNS for the whole network during backups
      stopDuringBackup = false;
    };
  }
  (lib.mkIf cfg.enable {
    sops.secrets."adguard/password_hash".owner = user.name;

    networking.nameservers = dnsServers;

    services.resolved.settings.Resolve = {
      DNSSEC = lib.mkForce false;
      FallbackDNS = lib.mkForce dnsServers;
      DNSStubListener = lib.mkForce "no";
    };

    containers.adguard = {
      bindMounts.${passwordSecret}.isReadOnly = true;

      forwardPorts =
        let
          mkDnsPort = protocol: {
            hostPort = dnsPort;
            inherit protocol;
          };
        in
        lib.map mkDnsPort [
          "tcp"
          "udp"
        ];

      config = {
        networking.nameservers = [ "127.0.0.1" ];

        services.resolved.enable = lib.mkForce false;

        networking.firewall = rec {
          allowedTCPPorts = [ dnsPort ];
          allowedUDPPorts = allowedTCPPorts;
        };

        systemd.services.adguardhome = {
          serviceConfig = {
            DynamicUser = lib.mkForce false;
            User = user.name;
            Group = user.group;
          };
          # Runs after the module has written AdGuardHome.yaml from `settings`.
          # Never fatal: DNS must keep working even if the web UI login can't be set.
          # No `sed -i`: it fchown()s its temp file, which the unit's seccomp filter
          # (~@privileged) kills. Write a temp file and rename it, like the module does.
          preStart = lib.mkAfter ''
            config_file="$STATE_DIRECTORY/AdGuardHome.yaml"
            if hash="$(< "${passwordSecret}")" && [ -n "$hash" ] \
              && sed "s|${passwordPlaceholder}|$hash|" "$config_file" > "$config_file.tmp" \
              && mv "$config_file.tmp" "$config_file"; then
              :
            else
              rm -f "$config_file.tmp"
              echo "WARNING: could not set the web UI password from ${passwordSecret}" >&2
            fi
          '';
        };

        services.adguardhome = {
          enable = true;
          allowDHCP = false;
          openFirewall = true;

          settings = {
            log.enabled = true;
            http.address = "0.0.0.0:${toString cfg.containerPort}";
            users = [
              {
                name = userName;
                password = passwordPlaceholder;
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
              allowed_clients = config.modules.nixos.containers.lanSubnets;
              upstream_dns = [
                "https://dns.quad9.net/dns-query"
                "tls://dns.quad9.net"
              ];
              bootstrap_dns = bootstrapDns;
              upstream_mode = "parallel";
              ratelimit = 0;
              edns_client_subnet.enabled = false;
              enable_dnssec = true;
              blocking_mode = "default";
            };
            filtering.filters_update_interval = 12;
            filters = [
              {
                enabled = true;
                url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
                name = "AdGuard DNS filter";
                id = 1;
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
              {
                enabled = true;
                url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt";
                name = "Steven Black's List";
                id = 1789578839;
              }
              {
                enabled = true;
                url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt";
                name = "AdGuard DNS Popup Hosts filter";
                id = 1789578840;
              }
            ];
          };
        };
      };
    };
  })
]
