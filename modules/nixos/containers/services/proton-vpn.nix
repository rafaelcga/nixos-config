{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg_containers = config.modules.nixos.containers.services;
  cfg = cfg_containers.proton-vpn;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  wireguardInterface = "wg-proton";

  containersBehindVpn =
    let
      doKeep =
        name: containerConfig:
        let
          isNotItself = name != cfg.name;
          isBehindVpn = containerConfig.enable && containerConfig.behindVpn;
        in
        isNotItself && isBehindVpn;
    in
    lib.filterAttrs doKeep cfg_containers;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.proton-vpn = {
      enable = containersBehindVpn != { };
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
                  wg = lib.getExe pkgs.wireguard-tools;
                  iptablesBin = lib.getExe' pkgs.iptables binName;
                in
                ''
                  ${iptablesBin} ${action} OUTPUT \
                    ! -o ${wireguardInterface} \
                    -m mark ! --mark $(${wg} show ${wireguardInterface} fwmark) \
                    -m addrtype ! --dst-type LOCAL \
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

          preDownFile = pkgs.writeShellScript "wg_containers_predown.sh" ''
            ${mkLookupRules "del"}
            ${mkAllowLan "-D"}
            ${mkKillSwitch "-D"}
          '';
          # Use PersistentKeepalive to avoid the tunnel from dying
        in
        ''
          [Interface]
          PrivateKey = ${config.sops.placeholder."wireguard/proton/private_key"}
          Address = 10.2.0.2/32
          DNS = 10.2.0.1
          MTU = 1420
          PostUp = ${postUpFile}
          PreDown = ${preDownFile}

          [Peer]
          PublicKey = ${config.sops.placeholder."wireguard/proton/public_key"}
          AllowedIPs = 0.0.0.0/0, ::/0
          Endpoint = ${config.sops.placeholder."wireguard/proton/endpoint"}:51820
          PersistentKeepalive = 15
        '';
    };

    systemd.services =
      let
        mkWaitForVpn =
          name: containerConfig:
          let
            vpnContainer = "container@proton-vpn.service";
          in
          lib.nameValuePair "container@${name}" rec {
            after = [ vpnContainer ];
            requires = after;
          };
      in
      lib.mapAttrs' mkWaitForVpn containersBehindVpn;

    containers =
      let
        vpnContainerConfig = {
          proton-vpn = {
            enableTun = true;

            bindMounts = {
              "${config.sops.templates."${wireguardInterface}.conf".path}" = {
                isReadOnly = true;
              };
            };

            config = {
              networking = {
                nat = {
                  enable = true;
                  enableIPv6 = true;
                  externalInterface = wireguardInterface;
                  internalInterfaces = [ "eth0" ];
                };

                firewall.allowedUDPPorts = [ 51820 ];

                wg-quick.interfaces."${wireguardInterface}" = {
                  configFile = config.sops.templates."${wireguardInterface}.conf".path;
                };
              };
            };
          };
        };

        modifiedConfigs =
          let
            vpnLocalIp = utils.removeMask config.containers.proton-vpn.localAddress;
            mkModifiedConfig = name: containerConfig: {
              config = {
                networking.defaultGateway = lib.mkForce vpnLocalIp;
              };
            };
          in
          lib.mapAttrs mkModifiedConfig containersBehindVpn;
      in
      lib.mkMerge [
        vpnContainerConfig
        modifiedConfigs
      ];
  })
]
