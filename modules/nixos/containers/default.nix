{
  inputs,
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  enabledContainers =
    let
      isEnabled = _: containerConfig: containerConfig.enable;
    in
    lib.filterAttrs isEnabled cfg.services;
in
{
  imports = [ ./services ];

  options.modules.nixos.containers = {
    hostAddress = lib.mkOption {
      type = lib.types.str;
      default = "172.22.0.1"; # 172.22.0.0/24
      description = "Host local IPv4 address";
    };

    hostAddress6 = lib.mkOption {
      type = lib.types.str;
      default = "fc00::1"; # fc00::1/64
      description = "Host local IPv6 address";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/containers";
      description = "Default host directory where container data will be saved";
    };

    containerUid = lib.mkOption {
      type = lib.types.int;
      default = 2000;
      description = "Container's main user account UID";
    };

    containerGroup = lib.mkOption {
      type = lib.types.str;
      default = config.users.users.${userName}.group;
      readOnly = true;
      internal = true;
      description = "Container's main user account group";
    };

    wireguardInterface = lib.mkOption {
      type = lib.types.str;
      default = "wg-containers";
      readOnly = true;
      internal = true;
      description = "Name of the WireGuard interface in the containers";
    };

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./container-options.nix { inherit cfg; }));
      default = { };
      description = "Enabled containers";
    };
  };

  config = lib.mkIf (enabledContainers != { }) {
    sops = {
      secrets = {
        "wireguard/proton/public_key" = { };
        "wireguard/proton/private_key" = { };
        "wireguard/proton/endpoint" = { };
      };

      templates."${cfg.wireguardInterface}.conf".content =
        let
          localIpv4 = [
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
          ];

          localIpv6 = [
            "fc00::/7"
            "fe80::/10"
          ];

          isIpv4 = address: lib.hasInfix "." address;
          isIpv6 = address: lib.hasInfix ":" address;

          mkRoutes =
            action:
            let
              templateRoute =
                address:
                let
                  ip = lib.getExe' pkgs.iproute2 "ip";
                  command = "${ip}" + lib.optionalString (isIpv6 address) " -6";
                  gateway = if isIpv4 address then cfg.hostAddress else cfg.hostAddress6;
                in
                "${command} route ${action} ${address} via ${gateway}";
            in
            lib.concatMapStringsSep "\n" templateRoute (localIpv4 ++ localIpv6);

          mkAllowRules =
            action:
            let
              allowedIps = [
                cfg.hostAddress
                cfg.hostAddress6
              ]
              ++ localIpv4
              ++ localIpv6;

              templateRule =
                ip:
                let
                  binName = if isIpv4 ip then "iptables" else "ip6tables";
                  iptablesBin = lib.getExe' pkgs.iptables binName;
                in
                "${iptablesBin} ${action} OUTPUT -d ${ip} -j ACCEPT";
            in
            lib.concatMapStringsSep "\n" templateRule allowedIps;

          mkKillSwitchRule =
            action:
            let
              templateRule =
                binName:
                let
                  iptablesBin = lib.getExe' pkgs.iptables binName;
                  wg = lib.getExe pkgs.wireguard-tools;
                in
                ''
                  ${iptablesBin} ${action} OUTPUT \
                    ! -o ${cfg.wireguardInterface} \
                    -m mark ! --mark $(${wg} show ${cfg.wireguardInterface} fwmark) \
                    -m addrtype ! --dst-type LOCAL \
                    -j REJECT
                '';
            in
            lib.concatMapStringsSep "\n" templateRule [
              "iptables"
              "ip6tables"
            ];

          postUpFile = pkgs.writeShellScript "killswitch_postup.sh" ''
            ${mkRoutes "add"}
            ${mkAllowRules "-A"}
            ${mkKillSwitchRule "-A"}
          '';

          preDownFile = pkgs.writeShellScript "killswitch_predown.sh" ''
            ${mkRoutes "del"}
            ${mkAllowRules "-D"}
            ${mkKillSwitchRule "-D"}
          '';
        in
        ''
          [Interface]
          PrivateKey = ${config.sops.placeholder."wireguard/proton/private_key"}
          Address = 10.2.0.2/32
          DNS = 10.2.0.1
          PostUp = ${postUpFile}
          PreDown = ${preDownFile}

          [Peer]
          PublicKey = ${config.sops.placeholder."wireguard/proton/public_key"}
          AllowedIPs = 0.0.0.0/0, ::/0
          Endpoint = ${config.sops.placeholder."wireguard/proton/endpoint"}
        '';
    };

    networking = {
      nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = config.modules.nixos.networking.defaultInterface;
        internalInterfaces = [ (if config.networking.nftables.enable then "ve-*" else "ve-+") ];
      };

      # Prevent NetworkManager from managing container interfaces
      # https://nixos.org/manual/nixos/stable/#sec-container-networking
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [ "interface-name:ve-*" ];
      };
    };

    users.users.container = {
      uid = cfg.containerUid;
      group = cfg.containerGroup;
      isSystemUser = true;
    };

    systemd.tmpfiles.settings =
      let
        mkContainerDirs =
          name: containerConfig:
          lib.nameValuePair "10-container-${name}" {
            "${cfg.dataDir}/${name}".d = { };
          };
      in
      lib.mapAttrs' mkContainerDirs enabledContainers;

    containers =
      let
        baseConfigs =
          let
            mkBaseConfig =
              name: containerConfig:
              lib.mkMerge [
                {
                  autoStart = true;
                  privateNetwork = true;
                  privateUsers = "identity";

                  forwardPorts =
                    let
                      mkForwardPort =
                        serviceName:
                        let
                          hostPort = containerConfig.hostPorts.${serviceName};
                          containerPort = containerConfig.containerPorts.${serviceName};
                        in
                        lib.optionals (hostPort != null && containerPort != null) [
                          {
                            inherit hostPort containerPort;
                            protocol = "tcp";
                          }
                        ];

                      serviceNames = lib.attrNames containerConfig.containerPorts;
                    in
                    (lib.concatMap mkForwardPort serviceNames) ++ containerConfig.extraForwardPorts;

                  bindMounts = lib.mkMerge [
                    (lib.mkIf (containerConfig.containerDataDir != null) {
                      "${containerConfig.containerDataDir}" = {
                        hostPath = "${cfg.dataDir}/${name}";
                        isReadOnly = false;
                      };
                    })
                    containerConfig.bindMounts
                  ];

                  config = {
                    # Use systemd-resolved inside the container
                    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
                    networking.useHostResolvConf = lib.mkForce false;
                    services.resolved.enable = true;

                    users.users."${name}" = {
                      uid = cfg.containerUid;
                      group = cfg.containerGroup;
                      isSystemUser = true;
                    };

                    system.stateVersion = config.system.stateVersion;
                  };
                }
                (lib.mkIf containerConfig.behindVpn {
                  enableTun = true;

                  bindMounts = {
                    "${config.sops.templates."${cfg.wireguardInterface}.conf".path}" = {
                      isReadOnly = true;
                    };
                  };

                  config = {
                    networking.wg-quick.interfaces."${cfg.wireguardInterface}" = {
                      configFile = config.sops.templates."${cfg.wireguardInterface}.conf".path;
                    };
                  };
                })
              ];
          in
          lib.mapAttrs mkBaseConfig enabledContainers;

        addressConfigs =
          let
            sortedNames = lib.sort lib.lessThan (lib.attrNames enabledContainers);
            # Using imap1, index starts from 1
            mkValuePairs = index: name: {
              inherit name;
              value = {
                inherit (cfg) hostAddress hostAddress6;
                localAddress = utils.addToLastOctet cfg.hostAddress index;
                localAddress6 = utils.addToLastHextet cfg.hostAddress6 index;
              };
            };
          in
          lib.listToAttrs (lib.imap1 mkValuePairs sortedNames);
      in
      lib.mkMerge [
        baseConfigs
        addressConfigs
      ];
  };
}
