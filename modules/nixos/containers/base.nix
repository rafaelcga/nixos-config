{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers;

  mkCommonConfig = name: instance: {
    autoStart = true;
    privateNetwork = true;
    inherit (cfg) hostAddress hostAddress6;
    inherit (instance) localAddress localAddress6;

    config = {
      system.stateVersion = config.system.stateVersion;
    };
  };

  mkGpuConfig =
    name: instance:
    let
      mkPath = device: "/dev/dri/${device}";
      mkAllowedDevice = device: {
        node = mkPath device;
        modifier = "rw";
      };
      mkGpuBindMount = device: {
        hostPath = mkPath device;
        isReadOnly = false;
      };
    in
    lib.mkIf instance.gpuPassthrough {
      allowedDevices = map mkAllowedDevice instance.gpuDevices;
      bindMounts = lib.genAttrs' instance.gpuDevices (
        device: lib.nameValuePair (mkPath device) (mkGpuBindMount device)
      );
    };

  mkBaseConfig =
    name: instance:
    lib.mkIf instance.enable (
      lib.mkMerge [
        (mkCommonConfig name instance)
        { inherit (instance) bindMounts; }
        (mkGpuConfig name instance)
      ]
    );

  bindMountOpts =
    { name, ... }:
    {
      options = {
        hostPath = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Location of the host path to be mounted.";
        };
        isReadOnly = lib.mkOption {
          default = true;
          type = lib.types.bool;
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

  internalInterface = if config.networking.nftables.enable then "ve-*" else "ve-+";

  webPorts =
    let
      allWebPorts = lib.mapAttrsToList (_: instance: instance.webPort) cfg.instances;
    in
    lib.filter (port: port != null) allWebPorts;
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
  };
}
