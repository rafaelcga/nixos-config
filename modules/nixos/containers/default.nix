{
  inputs,
  config,
  lib,
  userName,
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

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/containers";
      description = "Default host directory where container data will be saved";
    };

    containerUid = lib.mkOption {
      type = lib.types.int;
      default = 2000;
      description = "UID of the container's user";
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
      };

      # Prevent NetworkManager from managing container interfaces
      # https://nixos.org/manual/nixos/stable/#sec-container-networking
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [ "interface-name:ve-*" ];
      };
    };

    users.users.container = {
      uid = cfg.containerUid;
      inherit (config.users.users.${userName}) group;
      isSystemUser = true;
    };

    systemd.tmpfiles.settings =
      let
        mkContainerDirs =
          name: containerConfig:
          lib.nameValuePair "10-container-${name}" {
            "${cfg.dataDir}/${name}".d = { };
          };
      in
      lib.mapAttrs' mkContainerDirs enabledContainers;

    containers =
      let
        baseConfigs =
          let
            mkBaseConfig = name: containerConfig: {
              autoStart = true;
              privateNetwork = true;
              privateUsers = "identity";

              config = {
                # Use systemd-resolved inside the container
                # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
                networking.useHostResolvConf = lib.mkForce false;
                services.resolved.enable = true;

                users.users."${name}" = {
                  uid = cfg.containerUid;
                  inherit (config.users.users.${userName}) group;
                  isSystemUser = true;
                };

                system.stateVersion = config.system.stateVersion;
              };
            };
          in
          lib.mapAttrs mkBaseConfig enabledContainers;

        portConfigs =
          let
            mkForwardPorts =
              _: containerConfig:
              let
                createForward =
                  serviceName:
                  let
                    hostPort = containerConfig.hostPorts.${serviceName};
                    containerPort = containerConfig.containerPorts.${serviceName};
                  in
                  lib.optionals (hostPort != null && containerPort != null) [
                    {
                      inherit hostPort containerPort;
                      protocol = "tcp";
                    }
                  ];

                serviceNames = lib.attrNames containerConfig.containerPorts;
              in
              {
                forwardPorts = (lib.concatMap createForward serviceNames) ++ containerConfig.extraForwardPorts;
              };
          in
          lib.mapAttrs mkForwardPorts enabledContainers;

        bindConfigs =
          let
            mkBindMounts = name: containerConfig: {
              bindMounts = lib.mkMerge [
                (lib.mkIf (containerConfig.containerDataDir != null) {
                  "${containerConfig.containerDataDir}" = {
                    hostPath = "${cfg.dataDir}/${name}";
                    isReadOnly = false;
                  };
                })
                containerConfig.bindMounts
              ];
            };
          in
          lib.mapAttrs mkBindMounts enabledContainers;

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
        bindConfigs
        portConfigs
        addressConfigs
      ];
  };
}
