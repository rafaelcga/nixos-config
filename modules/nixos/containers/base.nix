{ config, lib, ... }:
let
  inherit (config.modules.nixos) user;
  cfg = config.modules.nixos.containers;

  mkBaseConfig =
    name: instance:
    let
      mkDriPath = device: "/dev/dri/${device}";
      mkAllowedDevice = device: {
        node = mkDriPath device;
        modifier = "rw";
      };
      mkGpuBindMount = device: {
        hostPath = mkDriPath device;
        isReadOnly = false;
      };

      gpuConfig = lib.mkIf instance.gpuPassthrough {
        allowedDevices = map mkAllowedDevice instance.gpuDevices;
        bindMounts = lib.genAttrs' instance.gpuDevices (
          device: lib.nameValuePair (mkDriPath device) (mkGpuBindMount device)
        );
      };
    in
    lib.mkIf instance.enable (
      lib.mkMerge [
        {
          inherit (cfg) hostAddress hostAddress6;
          inherit (instance) localAddress localAddress6 bindMounts;

          autoStart = true;
          privateNetwork = true;

          config = {
            system.stateVersion = config.system.stateVersion;
          };
        }
        gpuConfig
      ]
    );

  mkServiceOverrides =
    name: instance:
    let
      containerService = "container@${name}";
      directoryService = "create-container-directories@${name}";
      getHostPath = mountPoint: bindMount: bindMount.hostPath or mountPoint;
      hostPaths = lib.unique (lib.mapAttrsToList getHostPath config.containers.${name}.bindMounts);
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

  internalInterface = if config.networking.nftables.enable then "ve-*" else "ve-+";

  webPorts =
    let
      instancesWithWebPorts = lib.filterAttrs (
        _: instance: instance.enable && (instance.webPort != null)
      ) cfg.instances;
    in
    lib.mapAttrsToList (_: instance: instance.webPort) instancesWithWebPorts;

  bindMountOpts = {
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
  };

  containerOpts =
    { name, ... }:
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

        webPort = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.unsigned;
          default = null;
          description = "Host port for the container's web interface";
        };

        bindMounts = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule bindMountOpts);
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
    };
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
        internalInterfaces = [ internalInterface ];
        inherit (cfg) externalInterface;
        enableIPv6 = true;
      };

      firewall.allowedTCPPorts = webPorts;

      # Prevent NetworkManager from managing container interfaces
      # https://nixos.org/manual/nixos/stable/#sec-container-networking
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [ "interface-name:ve-*" ];
      };
    };

    containers = lib.mapAttrs mkBaseConfig cfg.instances;

    systemd.services = lib.mkMerge (lib.mapAttrsToList mkServiceOverrides cfg.instances);
  };
}
