{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };
in
{
  imports = [
    ./servarr.nix
  ];

  options.modules.nixos.containers = {
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

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./container-options.nix));
      default = { };
      description = "Enabled containers";
    };
  };

  config = {
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

    containers =
      let
        enabledContainers = lib.filterAttrs (_: service: service.enable) cfg.services;
      in
      lib.mkMerge [
        (
          let
            sortedNames = lib.sort lib.lessThan (lib.attrNames enabledContainers);
            # Using imap1, index starts from 1
            mkValuePairs = index: name: {
              inherit name;
              value = {
                inherit (cfg) hostAddress hostAddress6;
                localAddress = utils.addToLastOctet cfg.hostAddress index;
                localAddress6 = utils.addToLastHextet cfg.hostAddress6 index;
              };
            };
          in
          lib.listToAttrs (lib.imap1 mkValuePairs sortedNames)
        )
      ];
  };
}
