{ config, lib, ... }:
let
  cfg = config.modules.containers;
  usesNetworkManager = config.networking.networkmanager.enable;
  internalInterface = if config.networking.nftables.enable then "ve-*" else "ve-+";

  commonContainerConfig = {
    autoStart = true;
    privateNetwork = true;
    inherit (cfg) hostAddress hostAddress6;
    config = {
      system.stateVersion = config.system.stateVersion;
    };
  };
in
{
  options.modules.containers = {
    enable = lib.mkEnableOption "NixOS containers configuration";
    externalInterface = lib.mkOption {
      type = lib.types.str; # no default to make it required
      description = "External interface for NAT";
    };
    hostAddress = lib.mkOption {
      default = "192.168.100.10";
      type = lib.types.str;
      description = "Host IPv4 address";
    };
    hostAddress6 = lib.mkOption {
      default = "fc00::1";
      type = lib.types.str;
      description = "Host IPv6 address";
    };
  };

  imports = lib.optionals cfg.enable (lib.local.listNixPaths { rootDir = ./.; });

  config = lib.mkIf cfg.enable {
    # TODO: Import the containers and do recursiveUpdate with commonContainerConfig
    # and then overriding with each containers configuration

    networking = {
      nat = {
        enable = true;
        internalInterfaces = [ internalInterface ];
        inherit (cfg) externalInterface;
        enableIPv6 = true;
      };
      # Prevent NetworkManager from managing container interfaces
      # https://nixos.org/manual/nixos/stable/#sec-container-networking
      networkmanager = lib.mkIf usesNetworkManager {
        unmanaged = [ "interface-name:ve-*" ];
      };
    };
  };
}
