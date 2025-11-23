{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  enabledContainers =
    let
      isEnabled = _: containerConfig: containerConfig.enable;
    in
    lib.filterAttrs isEnabled cfg.services;
in
{
  imports = [ ./services ];

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

  config = lib.mkIf (enabledContainers != { }) {
    networking = {
      nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = config.modules.nixos.networking.defaultInterface;
        internalInterfaces = [ (if config.networking.nftables.enable then "ve-*" else "ve-+") ];
        forwardPorts =
          let
            mkForwardPorts =
              name: containerConfig:
              let
                inherit (config.containers.${name}) localAddress;
                containerForwards =
                  let
                    containerServices = lib.attrNames containerConfig.containerPorts;
                    createForward =
                      serviceName:
                      let
                        hostPort = containerConfig.hostPorts.${serviceName};
                        containerPort = containerConfig.containerPorts.${serviceName};
                      in
                      lib.optionals (hostPort != null && containerPort != null) [
                        {
                          sourcePort = hostPort;
                          proto = "tcp";
                          destination = "${localAddress}:${builtins.toString containerPort}";
                        }
                      ];
                  in
                  lib.concatMap createForward containerServices;

                extraPortForwards =
                  let
                    convertForwardPorts = forwardPort: {
                      sourcePort = forwardPort.hostPort;
                      proto = forwardPort.protocol;
                      destination = "${localAddress}:${builtins.toString forwardPort.containerPort}";
                    };
                  in
                  lib.map convertForwardPorts containerConfig.extraForwardPorts;
              in
              containerForwards ++ extraPortForwards;
          in
          lib.concatLists (lib.mapAttrsToList mkForwardPorts enabledContainers);
      };

      # Prevent NetworkManager from managing container interfaces
      # https://nixos.org/manual/nixos/stable/#sec-container-networking
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [ "interface-name:ve-*" ];
      };
    };

    containers =
      let
        baseConfigs =
          let
            mkBaseConfig = _: containerConfig: {
              autoStart = true;
              privateNetwork = true;

              config = {
                # Use systemd-resolved inside the container
                # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
                networking.useHostResolvConf = lib.mkForce false;
                services.resolved.enable = true;

                system.stateVersion = config.system.stateVersion;
              };
            };
          in
          lib.mapAttrs mkBaseConfig enabledContainers;

        addressConfigs =
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
          lib.listToAttrs (lib.imap1 mkValuePairs sortedNames);
      in
      lib.mkMerge [
        baseConfigs
        addressConfigs
      ];
  };
}
