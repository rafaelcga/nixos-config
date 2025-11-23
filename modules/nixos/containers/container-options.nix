{
  config,
  lib,
  name,
  ...
}:
let
  cfg = config.modules.nixos.containers;

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

  mountOpts = {
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
in
{
  options = {
    enable = lib.mkEnableOption "Enable container@${name}";

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
      internal = true;
      description = "Exposed container port";
    };

    containerPorts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.port);
      default = { };
      internal = true;
      description = "Exposed container services mapped to their ports";
    };

    bindMounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule mountOpts);
      default = { };
      description = "Attribute set of directories to bind to the container";
    };

    extraForwardPorts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule portOpts);
      default = [ ];
      internal = true;
      description = "Extra forward ports for a container";
    };

    containerDataDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      internal = true;
      description = "Path of aggregated data from the container to bind to ${cfg.dataDir}";
    };

    gpuPassthrough = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to passthrough the host GPU devices to the container.
      '';
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
  ];
}
