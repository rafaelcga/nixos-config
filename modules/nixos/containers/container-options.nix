{
  inputs,
  hostConfig,
  config,
  lib,
  name,
  ...
}:
let
  cfg = hostConfig.modules.nixos.containers;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

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

    name = lib.mkOption {
      type = lib.types.str;
      default = name;
      readOnly = true;
      internal = true;
      description = "Container name";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      description = "Unique ID for the container";
    };

    engine = lib.mkOption {
      type = lib.types.enum [
        "nspawn"
        "oci"
      ];
      default = "nspawn";
      description = "The container engine to use for this service.";
    };

    image = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The container image to use (Required if engine is 'oci').";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default =
        if config.engine == "oci" then
          cfg.bridge.ipv4.host
        else
          utils.addToAddress cfg.bridge.ipv4.host cfg.services.${name}.uid;
      readOnly = true;
      internal = true;
      description = "IPv4 of the container (localhost for OCI, bridge IP for nspawn)";
    };

    address6 = lib.mkOption {
      type = lib.types.str;
      default =
        if config.engine == "oci" then
          cfg.bridge.ipv6.host
        else
          utils.addToAddress cfg.bridge.ipv6.host cfg.services.${name}.uid;
      readOnly = true;
      internal = true;
      description = "IPv6 of the container (localhost for OCI, bridge IP for nspawn)";
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
      internal = true;
      description = "Exposed container port";
    };

    containerPorts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.port);
      default = { };
      internal = true;
      description = "Exposed container services mapped to their ports";
    };

    userMounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule mountOpts);
      default = { };
      description = ''
        Attribute set of user owned directories to be mounted to the containers.
        WARNING: Their owner and group will be mapped to be that of the user;
        do not mount system directories
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      internal = true;
      description = "Path of aggregated data from the container to mount at ${cfg.dataDir}";
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

    enableBackup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to backup this container's dataDir";
    };

    excludeFromBackup = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "downloads/**" ];
      description = "List of paths or patterns relative to the container's dataDir to exclude";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.containerPort != null) {
      hostPorts."${name}" = lib.mkDefault config.hostPort;
      containerPorts."${name}" = lib.mkDefault config.containerPort;
    })
  ];
}
