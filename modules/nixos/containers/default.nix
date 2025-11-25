{
  inputs,
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  hostBridge = "br-containers";
  prefixLength = {
    ipv4 = 24;
    ipv6 = 64;
  };

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

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./container-options.nix { inherit cfg; }));
      default = { };
      description = "Enabled containers";
    };
  };

  config = lib.mkIf (enabledContainers != { }) {
    networking = {
      nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = config.modules.nixos.networking.defaultInterface;
        internalInterfaces = [ hostBridge ];
      };

      bridges."${hostBridge}".interfaces = [ ];
      interfaces."${hostBridge}" = {
        ipv4.addresses = [
          {
            address = cfg.hostAddress;
            prefixLength = prefixLength.ipv4;
          }
        ];
        ipv6.addresses = [
          {
            address = cfg.hostAddress6;
            prefixLength = prefixLength.ipv6;
          }
        ];
      };

      # Prevent NetworkManager from managing container interfaces
      # https://nixos.org/manual/nixos/stable/#sec-container-networking
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [
          "interface-name:ve-*"
          "interface-name:${hostBridge}"
        ];
      };
    };

    users.users.container = {
      uid = cfg.containerUid;
      group = cfg.containerGroup;
      isSystemUser = true;
    };

    systemd = {
      services =
        let
          mkWaitForBridge =
            name: containerConfig:
            let
              serviceName = "network-addresses-${hostBridge}.service";
            in
            lib.nameValuePair "container@${name}" {
              after = [ serviceName ];
              requires = [ serviceName ];
            };
        in
        lib.mapAttrs' mkWaitForBridge enabledContainers;

      tmpfiles.settings =
        let
          mkContainerDirs =
            name: containerConfig:
            lib.nameValuePair "10-container-${name}" {
              "${cfg.dataDir}/${name}".d = { };
            };
        in
        lib.mapAttrs' mkContainerDirs enabledContainers;
    };

    containers =
      let
        baseConfigs =
          let
            mkBaseConfig = name: containerConfig: {
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
            };
          in
          lib.mapAttrs mkBaseConfig enabledContainers;

        addressConfigs =
          let
            sortedNames = lib.sort lib.lessThan (lib.attrNames enabledContainers);
            # Using imap1, index starts from 1
            mkValuePairs =
              index: name:
              let
                localIpv4 = utils.addToLastOctet cfg.hostAddress index;
                localIpv6 = utils.addToLastHextet cfg.hostAddress6 index;
              in
              {
                inherit name;
                value = {
                  inherit hostBridge;
                  localAddress = "${localIpv4}/${builtins.toString prefixLength.ipv4}";
                  localAddress6 = "${localIpv6}/${builtins.toString prefixLength.ipv6}";

                  config = {
                    networking.defaultGateway = cfg.hostAddress;
                  };
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
