{ config, lib, ... }:
{
  imports = [
    ./servarr.nix
  ];

  networking.nat = {
    enable = true;
    enableIPv6 = true;
    internalInterfaces = [ (if config.networking.nftables.enable then "ve-*" else "ve-+") ];
    externalInterface = config.modules.nixos.networking.defaultInterface;
  };

  networkmanager = lib.mkIf config.networking.networkmanager.enable {
    unmanaged = [ "interface-name:ve-*" ];
  };
}
