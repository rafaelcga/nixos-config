{ config, lib, ... }:
{
  imports = [
    ./servarr.nix
  ];

  networking = {
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = config.modules.nixos.networking.defaultInterface;
      internalInterfaces = [ (if config.networking.nftables.enable then "ve-*" else "ve-+") ];
    };

    # Prevent NetworkManager from managing container interfaces
    # https://nixos.org/manual/nixos/stable/#sec-container-networking
    networkmanager = lib.mkIf config.networking.networkmanager.enable {
      unmanaged = [ "interface-name:ve-*" ];
    };
  };
}
