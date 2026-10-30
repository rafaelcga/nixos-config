{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg_containers = config.modules.nixos.containers.services;
  cfg = cfg_containers.proton-vpn;
  bridgeName = config.modules.nixos.containers.bridge.name;

  wireguardInterface = "wg-proton";

  nspawnBehindVpn =
    let
      doKeep =
        name: containerConfig:
        let
          isNotItself = name != cfg.name;
          isBehindVpn = containerConfig.enable && containerConfig.behindVpn;
          isNspawn = containerConfig.engine == "nspawn";
        in
        isNotItself && isBehindVpn && isNspawn;
    in
    lib.filterAttrs doKeep cfg_containers;

  ociBehindVpn =
    let
      doKeep =
        name: containerConfig:
        let
          isNotItself = name != cfg.name;
          isBehindVpn = containerConfig.enable && containerConfig.behindVpn;
          isOci = containerConfig.engine == "oci";
        in
        isNotItself && isBehindVpn && isOci;
    in
    lib.filterAttrs doKeep cfg_containers;

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
          # Not added 10.0.0.0/8, as it contains the VPN IPs themselves
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

    systemd.services =
      let
        vpnContainer = "container@proton-vpn.service";

        mkDependency =
          prefix: name: _:
          lib.nameValuePair "${prefix}${name}" {
            after = [ vpnContainer ];
            requires = [ vpnContainer ];
            bindsTo = [ vpnContainer ];
          };
      in
      lib.listToAttrs (
        (lib.mapAttrsToList (mkDependency "container@") nspawnBehindVpn)
        ++ (lib.mapAttrsToList (mkDependency "podman-") ociBehindVpn)
      );

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

    virtualisation.oci-containers.containers = lib.mapAttrs (name: containerConfig: {
      extraOptions = [
        "--network=bridge:name=${bridgeName}"
        "--ip=${containerConfig.address}"
        "--route=0.0.0.0/0,via=${cfg.address}"
        "--dns=10.2.0.1"
      ];
    }) ociBehindVpn;
  })
]
