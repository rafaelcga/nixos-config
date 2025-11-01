{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers;

  mkBaseConfig =
    name: instance:
    lib.mkIf instance.enable {
      autoStart = true;
      privateNetwork = true;
      inherit (cfg) hostAddress hostAddress6;
      inherit (instance) localAddress localAddress6;
      config = {
        system.stateVersion = config.system.stateVersion;
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
      };
    };

  internalInterface = if config.networking.nftables.enable then "ve-*" else "ve-+";

  webPorts =
    let
      allWebPorts = map (instance: instance.webPort) (lib.attrValues cfg.instances);
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
