{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances.servarr;

  services = lib.attrNames cfg.containerPorts;
in
{
  options.modules.nixos.containers.instances.servarr = {
    enable = lib.mkEnableOption "Enable container@servarr";

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

    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Container local IPv4 address";
    };

    localAddress6 = lib.mkOption {
      type = lib.types.str;
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
      internal = true;
      description = "Exposed container port";
    };

    containerPorts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.port);
      default = { };
      internal = true;
      description = "Exposed container services mapped to their ports";
    };

    containerDataDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      internal = true;
      description = "Path of aggregated data from the container";
    };
  };

  config = lib.mkIf cfg.enable {
    modules.nixos.containers.instances.servarr = {
      containerPorts = {
        lidarr = 8686;
        radarr = 7878;
        sonarr = 8989;
        prowlarr = 9696;
      };
      containerDataDir = "/var/lib/servarr";
    };

    sops = {
      secrets =
        let
          mkSecret = service: lib.nameValuePair "servarr/${service}" { };
        in
        lib.genAttrs' services mkSecret;

      templates."servarr-env".content =
        let
          mkApiKey =
            service:
            let
              apiKey = config.sops.placeholder."servarr/${service}";
            in
            "${lib.toUpper service}__AUTH__APIKEY=${apiKey}";
        in
        lib.concatMapStringsSep "\n" mkApiKey services;
    };

    containers.servarr = {
      autoStart = true;
      privateNetwork = true;

      inherit (cfg)
        hostAddress
        localAddress
        hostAddress6
        localAddress6
        ;

      bindMounts = {
        "${config.sops.templates."servarr-env".path}" = {
          isReadOnly = true;
        };
      };

      config = {
        services = lib.mkMerge [
          { resolved.enable = true; }
          (
            let
              mkService = name: {
                enable = true;
                dataDir = "${cfg.containerDataDir}/${name}";
                settings.server.port = cfg.containerPorts.${name};
                environmentFiles = [ config.sops.templates."servarr-env".path ];
                openFirewall = true;
              };
            in
            lib.genAttrs services mkService
          )
        ];

        system.stateVersion = config.system.stateVersion;
      };
    };
  };
}
