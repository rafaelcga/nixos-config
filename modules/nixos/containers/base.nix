{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers;
  user = config.users.users.${userName};

  mkServiceOverrides =
    name: instance:
    let
      containerService = "container@${name}";
      directoryService = "create-container-directories@${name}";

      getHostPath =
        mountPoint: bindMount: if bindMount.hostPath == null then mountPoint else bindMount.hostPath;
      container = config.containers.${name};
      hostPaths = lib.unique (lib.mapAttrsToList getHostPath container.bindMounts);

      createHostPath = path: ''
        if [[ ! -e "${path}" ]]; then
          echo "Creating directory: ${path}"
          mkdir -p "${path}"
          if [[ "${path}" == "${user.home}"* ]]; then
            chown -R "${user.name}:${user.group}" "${path}"
          fi
        else
          echo "Path already exists, skipping: ${path}"
        fi
      '';
    in
    lib.mkIf instance.enable {
      "${containerService}" = {
        after = [ "${directoryService}.service" ];
        requires = [ "${directoryService}.service" ];
      };

      "${directoryService}" = {
        description = "Create necessary host directories for ${containerService}";
        partOf = [ "${containerService}.service" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          set -euo pipefail

          ${lib.concatMapStringsSep "\n" createHostPath hostPaths}
        '';
      };
    };

  mkBaseConfig =
    name: instance:
    lib.mkIf instance.enable (
      lib.mkMerge [
        {
          inherit (cfg) hostBridge;
          inherit (instance)
            localAddress
            localAddress6
            bindMounts
            forwardPorts
            ;

          autoStart = true;
          privateNetwork = true;

          config = {
            system.stateVersion = config.system.stateVersion;
          };
        }
        (
          let
            nodePath = device: "/dev/dri/${device}";
            mkAllowedDevice = device: {
              node = nodePath device;
              modifier = "rw";
            };
            mkBindMount = device: {
              hostPath = nodePath device;
              isReadOnly = false;
            };
          in
          lib.mkIf instance.gpuPassthrough {
            allowedDevices = map mkAllowedDevice instance.gpuDevices;

            bindMounts = lib.genAttrs' instance.gpuDevices (
              device: lib.nameValuePair (nodePath device) (mkBindMount device)
            );
          }
        )
        (lib.mkIf instance.behindVpn {
          enableTun = true;

          bindMounts = {
            "${config.sops.templates."containers/${cfg.wireguardInterface}.conf".path}" = {
              isReadOnly = true;
            };
          };

          config = {
            networking.wg-quick.interfaces."${cfg.wireguardInterface}" = {
              configFile = config.sops.templates."containers/${cfg.wireguardInterface}.conf".path;
            };
          };
        })
      ]
    );

  portOpts = {
    options = {
      protocol = lib.mkOption {
        type = lib.types.str;
        default = "tcp";
        description = "The protocol specifier for port forwarding between host and container";
      };

      hostPort = lib.mkOption {
        type = lib.types.port;
        description = "Source port of the external interface on host";
      };

      containerPort = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        description = "Target port of container";
      };
    };
  };

  containerOpts =
    { name, config, ... }:
    {
      options = {
        enable = lib.mkEnableOption "Enable the ${name} container";

        localAddress = lib.mkOption {
          type = lib.types.str;
          apply = addr: "${addr}/24";
          description = "Container local IPv4 address";
        };

        localAddress6 = lib.mkOption {
          type = lib.types.str;
          apply = addr: "${addr}/64";
          description = "Container local IPv6 address";
        };

        hostPort = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          description = "Host port to map to exposed container port";
        };

        hostPorts = lib.mkOption {
          type = lib.types.attrsOf (lib.types.nullOr lib.types.port);
          default = { };
          description = "Host ports to map to exposed services in the container";
        };

        containerPort = lib.mkOption {
          type = lib.types.nullOr lib.types.port;
          default = null;
          visible = false;
          description = "Exposed container port";
        };

        containerPorts = lib.mkOption {
          type = lib.types.attrsOf (lib.types.nullOr lib.types.port);
          default = { };
          visible = false;
          description = "Exposed container services mapped to their ports";
        };

        forwardPorts = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule portOpts);
          readOnly = true;
          internal = true;
          description = "Services and their respective mapped ports";

          default =
            let
              services = lib.attrNames (lib.intersectAttrs config.containerPorts config.hostPorts);
              getPorts =
                service:
                let
                  hostPort = config.hostPorts.${service};
                  containerPort = config.containerPorts.${service};
                  protocol = "tcp";
                in
                lib.optionals (hostPort != null && containerPort != null) [
                  { inherit hostPort containerPort protocol; }
                ];
            in
            (lib.concatMap getPorts services) ++ config.extraForwardPorts;
        };

        extraForwardPorts = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule portOpts);
          default = [ ];
          visible = false;
          description = "Extra forward ports for a container";
        };

        containerDataDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          visible = false;
          description = "Path of aggregated data from the container to bind to ${cfg.dataDir}";
        };

        bindMounts = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                hostPath = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Location of the host path to be mounted.";
                };

                isReadOnly = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Determine whether the mounted path will be accessed in read-only mode.";
                };
              };
            }
          );
          default = { };
          description = "Attribute set of directories to bind to the container";
        };

        gpuPassthrough = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Whether to passthrough the host GPU devices to the container. The
            devices used are defined in
            `modules.nixos.containers.instances.<name>.gpuDevices`.
          '';
        };

        gpuDevices = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "card0"
            "renderD128"
          ];
          description = "Name of GPU devices to passthrough";
        };

        behindVpn = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to protect the container behind a VPN";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf (config.containerPort != null) {
          hostPorts."${name}" = lib.mkDefault config.hostPort;
          containerPorts."${name}" = lib.mkDefault config.containerPort;
        })
        (lib.mkIf (config.containerDataDir != null) {
          bindMounts."${config.containerDataDir}" = lib.mkDefault {
            hostPath = "${cfg.dataDir}/${name}";
            isReadOnly = false;
          };
        })
      ];
    };

  anyEnabled = lib.any (x: x) (lib.mapAttrsToList (_: instance: instance.enable) cfg.instances);

  getUniquePorts =
    protocol:
    let
      getPorts =
        let
          getHostPort = portConfig: lib.optionals (portConfig.protocol == protocol) [ portConfig.hostPort ];
        in
        _: instance: lib.concatMap getHostPort instance.forwardPorts;
      allPorts = lib.concatLists (lib.mapAttrsToList getPorts cfg.instances);
    in
    lib.unique allPorts;
in
{
  options.modules.nixos.containers = {
    hostAddress = lib.mkOption {
      type = lib.types.str;
      default = "172.22.0.1"; # 172.22.0.0/24
      description = "Host local IPv4 address";
    };

    hostAddress6 = lib.mkOption {
      type = lib.types.str;
      default = "fc00::1";
      description = "Host local IPv6 address";
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule containerOpts);
      default = { };
      description = "Enabled containers";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/containers";
      description = "Default host directory where container data will be saved";
    };

    hostBridge = lib.mkOption {
      type = lib.types.str;
      default = "br-containers";
      description = ''
        Name for the network bridge connecting the containers to the default
        network interface.
      '';
    };

    wireguardInterface = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = ''
        Name for the WireGuard interface when protecting a container behind a VPN
      '';
    };
  };

  config = lib.mkIf anyEnabled {
    sops = {
      secrets = {
        "wireguard/proton/public_key" = { };
        "wireguard/proton/private_key" = { };
        "wireguard/proton/endpoint" = { };
      };

      templates."containers/${cfg.wireguardInterface}.conf".content =
        let
          iptables = "${pkgs.iptables}/bin/iptables";
          ip6tables = "${pkgs.iptables}/bin/ip6tables";
          wg = "${pkgs.wireguard-tools}/bin/wg";

          postUpFile = pkgs.writeShellScript "killswitch_postup.sh" ''
            ${iptables} -I OUTPUT \
              ! -o ${cfg.wireguardInterface} \
              -m mark ! --mark $(${wg} show ${cfg.wireguardInterface} fwmark) \
              -m addrtype ! --dst-type LOCAL \
              -j REJECT
            ${ip6tables} -I OUTPUT \
              ! -o ${cfg.wireguardInterface} \
              -m mark ! --mark $(${wg} show ${cfg.wireguardInterface} fwmark) \
              -m addrtype ! --dst-type LOCAL \
              -j REJECT
          '';

          preDownFile = pkgs.writeShellScript "killswitch_predown.sh" ''
            ${iptables} -D OUTPUT \
              ! -o ${cfg.wireguardInterface} \
              -m mark ! --mark $(${wg} show ${cfg.wireguardInterface} fwmark) \
              -m addrtype ! --dst-type LOCAL \
              -j REJECT
            ${ip6tables} -D OUTPUT \
              ! -o ${cfg.wireguardInterface} \
              -m mark ! --mark $(${wg} show ${cfg.wireguardInterface} fwmark) \
              -m addrtype ! --dst-type LOCAL \
              -j REJECT
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
      bridges."${cfg.hostBridge}".interfaces = [ ];
      interfaces."${cfg.hostBridge}" = {
        ipv4.addresses = [
          {
            address = cfg.hostAddress;
            prefixLength = 24;
          }
        ];
        ipv6.addresses = [
          {
            address = cfg.hostAddress6;
            prefixLength = 64;
          }
        ];
      };

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

      firewall = {
        allowedTCPPorts = getUniquePorts "tcp";
        allowedUDPPorts = getUniquePorts "udp";
      };
    };

    containers = lib.mapAttrs mkBaseConfig cfg.instances;

    systemd.services = lib.mkMerge (lib.mapAttrsToList mkServiceOverrides cfg.instances);
  };
}
