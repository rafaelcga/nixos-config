{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg_containers = config.modules.nixos.containers.services;
  cfg = cfg_containers.proton-vpn;
  cfg_bridge = config.modules.nixos.containers.bridge;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  wireguardInterface = "wg-proton";
  # Port of the Proton WireGuard endpoint
  endpointPort = 51820;

  # Subnets reached directly instead of through the tunnel (LAN, home VPN,
  # containers). The tunnel is IPv4-only
  lanSubnets = lib.filter (
    subnet: !lib.hasInfix ":" subnet
  ) config.modules.nixos.containers.lanSubnets;

  # The Proton WireGuard config only carries an IPv4 address (10.2.0.2/32) and
  # no IPv6 route leaves the containers, so the OCI path is IPv4-only.
  #
  # Podman network used by VPN'd OCI containers: a macvlan on top of the
  # container bridge, with the VPN container as its only gateway. The name
  # embeds a hash of its definition, so changing any setting creates a fresh
  # network instead of `--ignore` silently keeping a stale one.
  ociNetworkArgs = [
    "-d"
    "macvlan"
    "--disable-dns"
    "-o"
    "parent=${cfg_bridge.name}"
    "--subnet"
    "${cfg_bridge.ipv4.address}/${toString cfg_bridge.ipv4.mask}"
    "--gateway"
    cfg.address
  ];
  ociNetworkPrefix = "${cfg_bridge.name}-vpn";
  ociNetwork = "${ociNetworkPrefix}-${
    builtins.substring 0 8 (builtins.hashString "sha256" (builtins.toJSON ociNetworkArgs))
  }";

  # Host-side macvlan "shim". A macvlan child cannot be reached from its own
  # parent interface, so without this the host (browser proxy, etc.) can't talk
  # to the OCI containers. All container `uid`s must stay below this offset (asserted).
  shimName = "vpn-shim";
  shimOffset = 250;
  shimAddress = utils.addToAddress cfg_bridge.ipv4.host shimOffset;

  mkBehindVpn =
    engine:
    let
      doKeep =
        name: containerConfig:
        name != cfg.name
        && containerConfig.enable
        && containerConfig.behindVpn
        && containerConfig.engine == engine;
    in
    lib.filterAttrs doKeep cfg_containers;

  nspawnBehindVpn = mkBehindVpn "nspawn";
  ociBehindVpn = mkBehindVpn "oci";

  anyBehindVpn = (nspawnBehindVpn != { }) || (ociBehindVpn != { });

  # Host ports that must be forwarded to VPN'd OCI containers. Macvlan
  # containers cannot use `podman -p`, so a socket proxy on the host takes over:
  # <host>:hostPort -> <container ip>:containerPort (via the vpn-shim).
  ociProxies = lib.concatLists (
    lib.mapAttrsToList (
      name: containerConfig:
      map (mapping: {
        inherit name;
        inherit (mapping) hostPort containerPort;
        inherit (containerConfig) address;
        unit = "vpn-proxy-${name}-${mapping.service}";
      }) containerConfig.portMappings
    ) ociBehindVpn
  );
in
lib.mkMerge [
  {
    modules.nixos.containers.services.proton-vpn = {
      uid = 5;
      enable = anyBehindVpn;
    };
  }
  (lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (containerConfig: containerConfig.uid < shimOffset) (
          lib.attrValues cfg_containers
        );
        message = "modules.nixos.containers: container uids must be below ${toString shimOffset}, which is reserved for ${shimName}";
      }
    ];

    sops = {
      secrets = {
        "wireguard/proton/public_key" = { };
        "wireguard/proton/private_key" = { };
        "wireguard/proton/endpoint" = { };
      };

      templates."${wireguardInterface}.conf".content =
        let
          # wg-quick sends everything into the tunnel except what the main table
          # routes more specifically than the default route, i.e. the container
          # bridge. The LAN and the home VPN only have the default route, so
          # look them up in the main table explicitly. (There is no kill switch
          # in here: the host-side `vpn-killswitch` table enforces it.)
          mkLookupRules =
            action:
            lib.concatMapStringsSep "\n" (
              block: "${lib.getExe' pkgs.iproute2 "ip"} rule ${action} to ${block} lookup main prio 2500"
            ) lanSubnets;

          postUpFile = pkgs.writeShellScript "wg_containers_postup.sh" (mkLookupRules "add");
          postDownFile = pkgs.writeShellScript "wg_containers_postdown.sh" (mkLookupRules "del");
        in
        ''
          [Interface]
          PrivateKey = ${config.sops.placeholder."wireguard/proton/private_key"}
          Address = 10.2.0.2/32
          DNS = 10.2.0.1
          MTU = 1420
          FwMark = 51820
          PostUp = ${postUpFile}
          PostDown = ${postDownFile}

          [Peer]
          PublicKey = ${config.sops.placeholder."wireguard/proton/public_key"}
          AllowedIPs = 0.0.0.0/0, ::/0
          Endpoint = ${config.sops.placeholder."wireguard/proton/endpoint"}:${toString endpointPort}
          PersistentKeepalive = 15
        '';
    };

    # 1. Lifecycle for both nspawn and OCI containers
    systemd.services = lib.mkMerge [
      # Create the macvlan network as ROOT, after the bridge exists, and drop
      # networks left over from older definitions.
      (lib.mkIf (ociBehindVpn != { }) {
        "podman-network-vpn" = {
          description = "Create Podman network for VPN routed containers";
          after = [
            "systemd-networkd.service"
            "container@proton-vpn.service"
          ];
          requires = [ "container@proton-vpn.service" ];
          wantedBy = [ "multi-user.target" ];
          path = [
            pkgs.podman
            pkgs.iproute2
            pkgs.coreutils
            pkgs.gnugrep
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            # networkd creates the bridge asynchronously; wait for it
            for _ in $(seq 1 30); do
              ip link show ${cfg_bridge.name} >/dev/null 2>&1 && break
              sleep 1
            done
            ip link show ${cfg_bridge.name} >/dev/null

            podman network create --ignore ${lib.escapeShellArgs ociNetworkArgs} ${ociNetwork}

            # Remove networks from previous definitions (including the old
            # unhashed one). Ones still in use are left alone.
            for net in $(podman network ls --format '{{.Name}}' \
              | grep -E '^${ociNetworkPrefix}(-[0-9a-f]{8})?$' \
              | grep -vx '${ociNetwork}' || true); do
              podman network rm "$net" || true
            done
          '';
        };
      })
      # Host-side TCP proxies replacing the unavailable `-p` port publishing
      (lib.listToAttrs (
        lib.map (
          proxy:
          lib.nameValuePair proxy.unit {
            description = "Forward :${toString proxy.hostPort} to ${proxy.name} behind the VPN";
            requires = [ "podman-${proxy.name}.service" ];
            after = [
              "podman-${proxy.name}.service"
              "${proxy.unit}.socket"
            ];
            serviceConfig = {
              ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min ${proxy.address}:${toString proxy.containerPort}";
              PrivateTmp = true;
              DynamicUser = true;
            };
          }
        ) ociProxies
      ))
      (
        let
          vpnContainer = "container@proton-vpn.service";

          mkNspawnDep =
            name: _:
            lib.nameValuePair "container@${name}" {
              after = [ vpnContainer ];
              requires = [ vpnContainer ];
              bindsTo = [ vpnContainer ];
            };

          mkOciDep =
            name: _:
            lib.nameValuePair "podman-${name}" {
              after = [
                vpnContainer
                "podman-network-vpn.service"
              ];
              requires = [
                vpnContainer
                "podman-network-vpn.service"
              ];
              bindsTo = [ vpnContainer ];
            };
        in
        lib.listToAttrs (
          (lib.mapAttrsToList mkNspawnDep nspawnBehindVpn) ++ (lib.mapAttrsToList mkOciDep ociBehindVpn)
        )
      )
    ];

    systemd.sockets = lib.listToAttrs (
      lib.map (
        proxy:
        lib.nameValuePair proxy.unit {
          wantedBy = [ "sockets.target" ];
          listenStreams = [ "0.0.0.0:${toString proxy.hostPort}" ];
        }
      ) ociProxies
    );

    # Host-side macvlan shim so the host can reach OCI containers on the
    # macvlan network (macvlan parent <-> child traffic is otherwise blocked).
    systemd.network = lib.mkIf (ociBehindVpn != { }) {
      netdevs."25-${shimName}" = {
        netdevConfig = {
          Kind = "macvlan";
          Name = shimName;
        };
        macvlanConfig.Mode = "bridge";
      };

      # Attach the shim to the bridge (merges with the existing 30-<bridge> unit)
      networks."30-${cfg_bridge.name}".networkConfig.MACVLAN = shimName;

      networks."31-${shimName}" = {
        matchConfig.Name = shimName;
        networkConfig.ConfigureWithoutCarrier = true;
        addresses = [ { Address = "${shimAddress}/32"; } ];
        # More specific /32 routes beat the connected bridge route
        routes = lib.map (containerConfig: {
          Destination = "${containerConfig.address}/32";
          PreferredSource = shimAddress;
          Scope = "link";
        }) (lib.attrValues ociBehindVpn);
        linkConfig.RequiredForOnline = "no";
      };
    };

    # 2. nspawn: route through the VPN container
    containers =
      let
        vpnContainerConfig = {
          proton-vpn = {
            enableTun = true;
            bindMounts = {
              "${config.sops.templates."${wireguardInterface}.conf".path}".isReadOnly = true;
            };
            config.networking = {
              nat = {
                enable = true;
                externalInterface = wireguardInterface;
                internalInterfaces = [ "eth0" ];
              };
              wg-quick.interfaces."${wireguardInterface}".configFile =
                config.sops.templates."${wireguardInterface}.conf".path;
            };
          };
        };

        modifiedConfigs = lib.mapAttrs (name: _: {
          config.systemd.network.networks."10-bridge".networkConfig.Gateway = lib.mkForce cfg.address;
        }) nspawnBehindVpn;
      in
      lib.mkMerge [
        vpnContainerConfig
        modifiedConfigs
      ];

    # 3. OCI: attach to the VPN macvlan network
    virtualisation.oci-containers.containers = lib.mapAttrs (name: containerConfig: {
      podman.user = lib.mkForce "root";
      ports = lib.mkForce [ ];
      extraOptions = [
        "--network=${ociNetwork}"
        "--ip=${containerConfig.address}"
        "--dns=10.2.0.1"
      ];
    }) ociBehindVpn;
  })
  # Restart the VPN container when a rotated key changes; the VPN'd containers
  # are bound to it and restart too
  (lib.mkIf cfg.enable {
    sops.templates."${wireguardInterface}.conf".restartUnits = [ "container@proton-vpn.service" ];
  })
  # The kill switch, enforced on the host. Without the tunnel (wg-quick failed
  # or stopped), the VPN container routes through the host, whose NAT would
  # send the traffic out with the home IP. Being outside the VPN container,
  # neither a failed tunnel nor a compromised VPN container can bypass it.
  (lib.mkIf cfg.enable {
    networking.nftables.tables.vpn-killswitch =
      let
        inherit (config.modules.nixos.networking) defaultInterface;
        behindVpnAddresses = lib.mapAttrsToList (_: containerConfig: containerConfig.address) (
          nspawnBehindVpn // ociBehindVpn
        );
        toSet = lib.concatStringsSep ", ";
        fromBridgeToInternet = ''iifname "${cfg_bridge.name}" oifname "${defaultInterface}"'';
      in
      {
        family = "inet";
        content = ''
          chain forward {
            type filter hook forward priority filter - 5; policy accept;

            # Containers behind the VPN: only the LAN/VPN subnets, never the
            # internet directly (their traffic must leave through the tunnel)
            ${fromBridgeToInternet} ip saddr { ${toSet behindVpnAddresses} } ip daddr != { ${toSet lanSubnets} } counter drop

            # The VPN container itself: only its WireGuard traffic to the endpoint
            ${fromBridgeToInternet} ip saddr ${cfg.address} meta l4proto != udp counter drop
            ${fromBridgeToInternet} ip saddr ${cfg.address} udp dport != ${toString endpointPort} counter drop
          }
        '';
      };
  })
]
