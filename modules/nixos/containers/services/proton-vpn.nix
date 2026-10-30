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

  # Podman network (macvlan on top of the container bridge) used by OCI containers
  ociVpnNetwork = "${cfg_bridge.name}-vpn";

  # Host-side macvlan "shim". A macvlan child cannot be reached from its own
  # parent interface, so without this the host (reverse proxy, etc.) can't talk
  # to the OCI containers. Pick an offset that no container `uid` uses.
  shimName = "vpn-shim";
  shimOffset = 250;
  shimV4 = utils.addToAddress cfg_bridge.ipv4.host shimOffset;
  shimV6 = utils.addToAddress cfg_bridge.ipv6.host shimOffset;

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
in
lib.mkMerge [
  {
    modules.nixos.containers.services.proton-vpn = {
      uid = 5;
      enable = anyBehindVpn;
    };
  }
  (lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "wireguard/proton/public_key" = { };
        "wireguard/proton/private_key" = { };
        "wireguard/proton/endpoint" = { };
      };

      templates."${wireguardInterface}.conf".content =
        let
          localIpv4 = [
            config.modules.nixos.home-vpn.network.subnet
            "172.16.0.0/12"
            "192.168.0.0/16"
          ];
          localIpv6 = [
            "fc00::/7"
            "fe80::/10"
          ];

          isIpv6 = address: lib.hasInfix ":" address;

          mkAllowLan =
            action:
            let
              ruleTemplate =
                block:
                let
                  binName = if (isIpv6 block) then "ip6tables" else "iptables";
                  iptablesBin = lib.getExe' pkgs.iptables binName;
                in
                ''
                  ${iptablesBin} ${action} INPUT -s ${block} -j ACCEPT
                  ${iptablesBin} ${action} OUTPUT -d ${block} -j ACCEPT
                  # Allow containers to talk to the LAN and each other through the gateway
                  ${iptablesBin} ${action} FORWARD -i eth0 -s ${block} -j ACCEPT
                  ${iptablesBin} ${action} FORWARD -o eth0 -d ${block} -j ACCEPT
                '';
            in
            lib.concatMapStringsSep "\n" ruleTemplate (localIpv4 ++ localIpv6);

          mkLookupRules =
            action:
            let
              ruleTemplate =
                block:
                let
                  ip = lib.getExe' pkgs.iproute2 "ip";
                  command = "${ip}" + lib.optionalString (isIpv6 block) " -6";
                in
                "${command} rule ${action} to ${block} lookup main prio 2500";
            in
            lib.concatMapStringsSep "\n" ruleTemplate (localIpv4 ++ localIpv6);

          mkKillSwitch =
            action:
            let
              ruleTemplate =
                binName:
                let
                  iptablesBin = lib.getExe' pkgs.iptables binName;
                in
                ''
                  # Block traffic originating from the VPN container itself from leaking
                  ${iptablesBin} ${action} OUTPUT \
                    ! -o ${wireguardInterface} \
                    -m mark ! --mark 51820 \
                    -m addrtype ! --dst-type LOCAL \
                    -j REJECT
                  # Block traffic forwarded from other containers from leaking
                  ${iptablesBin} ${action} FORWARD \
                    -i eth0 ! -o ${wireguardInterface} \
                    -j REJECT
                '';
            in
            lib.concatMapStringsSep "\n" ruleTemplate [
              "iptables"
              "ip6tables"
            ];

          postUpFile = pkgs.writeShellScript "wg_containers_postup.sh" ''
            ${mkLookupRules "add"}
            ${mkAllowLan "-I"} # Insert on top
            ${mkKillSwitch "-A"}
          '';

          postDownFile = pkgs.writeShellScript "wg_containers_postdown.sh" ''
            ${mkLookupRules "del"}
            ${mkAllowLan "-D"}
            ${mkKillSwitch "-D"}
          '';
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
          Endpoint = ${config.sops.placeholder."wireguard/proton/endpoint"}:51820
          PersistentKeepalive = 15
        '';
    };

    # 1. Lifecycle for both nspawn and OCI containers
    systemd.services = lib.mkMerge [
      # FIX 1 (ordering) + FIX 2 (gateway): create the macvlan network as ROOT,
      # after the bridge exists, with the VPN container as the *only* gateway.
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

            # NOTE: --ignore keeps an existing network untouched. If you change
            # subnet/gateway later, run `podman network rm ${ociVpnNetwork}` as
            # root (after stopping the containers) and restart this unit.
            podman network create \
              --ignore \
              --disable-dns \
              -d macvlan \
              -o parent=${cfg_bridge.name} \
              --subnet ${cfg_bridge.ipv4.address}/${toString cfg_bridge.ipv4.mask} \
              --gateway ${cfg.address} \
              --subnet ${cfg_bridge.ipv6.address}/${toString cfg_bridge.ipv6.mask} \
              --gateway ${cfg.address6} \
              ${ociVpnNetwork}
          '';
        };
      })
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

    # FIX 4: host-side macvlan shim so the host can reach OCI containers on the
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
        networkConfig = {
          ConfigureWithoutCarrier = true;
        };
        addresses = [
          { Address = "${shimV4}/32"; }
          {
            Address = "${shimV6}/128";
            DuplicateAddressDetection = "none";
          }
        ];
        # More specific /32 and /128 routes beat the connected bridge route
        routes = lib.concatMap (containerConfig: [
          {
            Destination = "${containerConfig.address}/32";
            PreferredSource = shimV4;
            Scope = "link";
          }
          {
            Destination = "${containerConfig.address6}/128";
            PreferredSource = shimV6;
          }
        ]) (lib.attrValues ociBehindVpn);
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
                enableIPv6 = true;
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
        "--network=${ociVpnNetwork}"
        "--ip=${containerConfig.address}"
        "--ip6=${containerConfig.address6}"
        "--dns=10.2.0.1"
      ];
    }) ociBehindVpn;
  })
]
