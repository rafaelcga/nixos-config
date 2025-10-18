{ config, lib, ... }:
let
  cfg = config.modules.containers;
  usesNetworkManager = config.networking.networkmanager.enable;
  internalInterface = if config.networking.nftables.enable then "ve-*" else "ve-+";
in
{
  options.modules.containers = {
    enable = lib.mkEnableOption "NixOS containers configuration";
    externalInterface = lib.mkOption {
      type = lib.types.str; # no default to make it required
      description = "External interface for NAT";
    };
    hostAddress = lib.mkOption {
      default = "172.22.0.1"; # 172.22.0.0/24
      type = lib.types.str;
      description = "Host local IPv4 address";
    };
    hostAddress6 = lib.mkOption {
      default = "fc00::1";
      type = lib.types.str;
      description = "Host local IPv6 address";
    };
    commonConfig = lib.mkOption {
      default = {
        autoStart = true;
        privateNetwork = true;
        inherit (cfg) hostAddress hostAddress6;
        config = {
          system.stateVersion = config.system.stateVersion;
        };
      };
      type = lib.types.attrs;
      description = "Common configuration applied to all containers";
    };
  };

  imports = lib.optionals cfg.enable (lib.local.listNixPaths { rootDir = ./.; });

  config = lib.mkIf cfg.enable {
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
