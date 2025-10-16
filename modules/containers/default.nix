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
