{ config, lib, ... }:
let
  inherit (config.modules.nixos) user;
  cfg = config.modules.nixos.containers;

  mkServiceOverrides =
    name: instance:
    let
      containerService = "container@${name}";
      directoryService = "create-container-directories@${name}";

      getHostPath =
        mountPoint: bindMount: if bindMount.hostPath == null then mountPoint else bindMount.hostPath;
      container = config.containers.${name};
      hostPaths = lib.unique (lib.mapAttrsToList getHostPath container.bindMounts);
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

          printf "${lib.concatStringsSep "\n" hostPaths}" \
            | while read path; do
              if [[ ! -f "$path" ]]; then
                mkdir -p "$path"
                if [[ "$path" == "${user.home}"* ]]; then
                  chown -R "${user.name}:${user.group}" "$path"
                fi
              fi
            done
        '';
      };
    };

  mkBaseConfig =
    name: instance:
    lib.mkIf instance.enable (
      lib.mkMerge [
        {
          inherit (cfg) hostAddress hostAddress6;
          inherit (instance) localAddress localAddress6 bindMounts;

          autoStart = true;
          privateNetwork = true;

          forwardPorts =
            let
              mkForwardPort = portPair: {
                inherit (portPair) hostPort containerPort;
                protocol = "tcp";
              };
            in
            map mkForwardPort instance.mappedPorts;

          config = {
            system.stateVersion = config.system.stateVersion;
          };
        }
        (
          let
            driPath = device: "/dev/dri/${device}";
            mkAllowedDevice = device: {
              node = driPath device;
              modifier = "rw";
            };
            mkBindMount = device: {
              hostPath = driPath device;
              isReadOnly = false;
            };
          in
          lib.mkIf instance.gpuPassthrough {
            allowedDevices = map mkAllowedDevice instance.gpuDevices;

            bindMounts = lib.genAttrs' instance.gpuDevices (
              device: lib.nameValuePair (driPath device) (mkBindMount device)
            );
          }
        )
      ]
    );

  containerOpts =
    { name, config, ... }:
    {
      options = {
        enable = lib.mkEnableOption "Enable the ${name} container";

        localAddress = lib.mkOption {
          type = lib.types.str;
          description = "Container local IPv4 address";
        };

        localAddress6 = lib.mkOption {
          type = lib.types.str;
          description = "Container local IPv6 address";
        };

        hostPort = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.unsigned;
          default = null;
          description = "Host port to map to exposed container port";
        };

        hostPorts = lib.mkOption {
          type = lib.types.attrsOf (lib.types.nullOr lib.types.ints.unsigned);
          default = { };
          description = "Host ports to map to exposed services in the container";
        };

        containerPort = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.unsigned;
          default = null;
          visible = false;
          description = "Exposed container port";
        };

        containerPorts = lib.mkOption {
          type = lib.types.attrsOf (lib.types.nullOr lib.types.ints.unsigned);
          default = { };
          visible = false;
          description = "Exposed container services mapped to their ports";
        };

        mappedPorts = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                hostPort = lib.mkOption {
                  type = lib.types.ints.unsigned;
                };

                containerPort = lib.mkOption {
                  type = lib.types.ints.unsigned;
                };
              };
            }
          );
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
                in
                lib.optionals (hostPort != null && containerPort != null) [ { inherit hostPort containerPort; } ];
            in
            lib.concatMap getPorts services;
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
      };

      config = lib.mkMerge [
        {
          hostPorts.main = lib.mkDefault config.hostPort;
          containerPorts.main = lib.mkDefault config.containerPort;
        }
        (lib.mkIf (config.containerDataDir != null) {
          bindMounts."${config.containerDataDir}" = lib.mkDefault {
            hostPath = "${cfg.dataDir}/${name}";
            isReadOnly = false;
          };
        })
      ];
    };

  mappedHostPorts =
    let
      getPorts = _: instance: map (portPair: portPair.hostPort) instance.mappedPorts;
      allPorts = lib.concatLists (lib.mapAttrsToList getPorts cfg.instances);
    in
    lib.unique allPorts;
in
{
  options.modules.nixos.containers = {
    externalInterface = lib.mkOption {
      type = lib.types.str; # no default to make it required
      description = "External interface for NAT";
    };

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
  };

  config = lib.mkIf (cfg.instances != { }) {
    networking = {
      nat = {
        enable = true;
        internalInterfaces = [ (if config.networking.nftables.enable then "ve-*" else "ve-+") ];
        inherit (cfg) externalInterface;
        enableIPv6 = true;
      };

      # Prevent NetworkManager from managing container interfaces
      # https://nixos.org/manual/nixos/stable/#sec-container-networking
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [ "interface-name:ve-*" ];
      };

      firewall.allowedTCPPorts = mappedHostPorts;
    };

    containers = lib.mapAttrs mkBaseConfig cfg.instances;

    systemd.services = lib.concatMapAttrs mkServiceOverrides cfg.instances;
  };
}
