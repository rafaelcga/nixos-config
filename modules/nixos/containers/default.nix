args@{
  inputs,
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers;
  user = config.users.users.${userName};

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  enabledContainers =
    let
      isEnabled = _: containerConfig: containerConfig.enable;
    in
    lib.filterAttrs isEnabled cfg.services;

  subnetOpts =
    { config, ... }:
    {
      options = {
        address = lib.mkOption {
          type = lib.types.str;
          description = "IPv4 or IPv6 address of the subnet";
        };

        mask = lib.mkOption {
          type = lib.types.int;
          description = "Subnet mask in CIDR notation";
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = utils.addToAddress config.address 1;
          readOnly = true;
          internal = true;
          description = "Address of the host machine within the container bridge";
        };
      };
    };

  bridgeOpts = {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "br-containers";
        description = "Container network bridge interface name";
      };

      ipv4 = lib.mkOption {
        type = lib.types.submodule subnetOpts;
        default = {
          address = "172.22.0.0";
          mask = 24;
        };
        description = "IPv4 subnet configuration";
      };

      ipv6 = lib.mkOption {
        type = lib.types.submodule subnetOpts;
        default = {
          address = "fc00::0";
          mask = 64;
        };
        description = "IPv6 subnet configuration";
      };
    };
  };

  userOpts = {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "container";
        description = "User name for containers UID in host system";
      };

      uid = lib.mkOption {
        type = lib.types.int;
        default = 2000;
        description = "Container's main user account UID";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = user.group;
        readOnly = true;
        internal = true;
        description = "Container's main user account group";
      };
    };
  };
in
{
  imports = [ ./services ];

  options.modules.nixos.containers = {
    bridge = lib.mkOption {
      type = lib.types.submodule bridgeOpts;
      default = { };
      description = "Container bridge network configuration";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/containers";
      description = "Default host directory where container data will be saved";
    };

    user = lib.mkOption {
      type = lib.types.submodule userOpts;
      default = { };
      description = "Container user configuration";
    };

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./container-options.nix args));
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
        internalInterfaces = [ cfg.bridge.name ];
      };

      bridges."${cfg.bridge.name}".interfaces = [ ];
      interfaces."${cfg.bridge.name}" = {
        ipv4.addresses = [
          {
            address = cfg.bridge.ipv4.host;
            prefixLength = cfg.bridge.ipv4.mask;
          }
        ];
        ipv6.addresses = [
          {
            address = cfg.bridge.ipv6.host;
            prefixLength = cfg.bridge.ipv6.mask;
          }
        ];
      };

      # Prevent NetworkManager from managing container interfaces
      # https://nixos.org/manual/nixos/stable/#sec-container-networking
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [
          "interface-name:ve-*"
          "interface-name:${cfg.bridge.name}"
        ];
      };
    };

    users.users.${cfg.user.name} = {
      inherit (cfg.user) uid group;
      isSystemUser = true;
    };

    systemd = {
      services =
        let
          mkWaitForBridge =
            name: containerConfig:
            let
              serviceName = "network-addresses-${cfg.bridge.name}.service";
            in
            lib.nameValuePair "container@${name}" rec {
              after = [ serviceName ];
              requires = after;
            };
        in
        lib.mapAttrs' mkWaitForBridge enabledContainers;

      tmpfiles.settings =
        let
          mkContainerDirs =
            let
              settingTemplate =
                name: _:
                lib.nameValuePair "${cfg.dataDir}/${name}" {
                  d = {
                    user = cfg.user.name;
                    inherit (cfg.user) group;
                    mode = "2755";
                  };
                };
            in
            {
              "10-make-container-dirs" = lib.mapAttrs' settingTemplate enabledContainers;
            };

          # Make user-defined dirs 775 and files 664 so that containers can
          # modify them (container's user and main user share user group)
          chmodUserMounts =
            let
              hostPaths =
                let
                  withUserMounts = lib.filterAttrs (
                    _: containerConfig: containerConfig.userMounts != { }
                  ) enabledContainers;

                  getHostPaths =
                    userMounts:
                    lib.mapAttrsToList (mountPoint: mountConfig: mountConfig.hostPath or mountPoint) userMounts;

                  allHostPaths = lib.concatMap (containerConfig: getHostPaths containerConfig.userMounts) (
                    lib.attrValues withUserMounts
                  );
                in
                lib.unique allHostPaths;

              settingsTemplate = path: {
                name = path;
                value = {
                  d = {
                    user = user.name;
                    inherit (user) group;
                    mode = "2775";
                  };
                  "A+".argument = "default:group::rwx";
                };
              };
            in
            {
              "10-chmod-container-binds" = lib.listToAttrs (lib.map settingsTemplate hostPaths);
            };
        in
        lib.mkMerge [
          mkContainerDirs
          chmodUserMounts
        ];
    };

    containers =
      let
        baseConfigs =
          let
            mkBaseConfig =
              name: containerConfig:
              let
                gpuDevices = [
                  "/dev/dri/card0"
                  "/dev/dri/renderD128"
                ];
              in
              {
                autoStart = true;
                privateNetwork = true;
                privateUsers = "identity";

                forwardPorts =
                  let
                    mkForwardPort =
                      serviceName:
                      let
                        hostPort = containerConfig.hostPorts.${serviceName};
                        containerPort = containerConfig.containerPorts.${serviceName};
                      in
                      lib.optionals (hostPort != null && containerPort != null) [
                        { inherit hostPort containerPort; }
                      ];

                    serviceNames = lib.attrNames containerConfig.containerPorts;
                  in
                  lib.concatMap mkForwardPort serviceNames;

                allowedDevices =
                  let
                    mkAllowedDevice = node: {
                      inherit node;
                      modifier = "rw";
                    };
                  in
                  lib.mkIf containerConfig.gpuPassthrough (lib.map mkAllowedDevice gpuDevices);

                bindMounts = lib.mkMerge [
                  (lib.mkIf (containerConfig.dataDir != null) {
                    "${containerConfig.dataDir}" = {
                      hostPath = "${cfg.dataDir}/${name}";
                      isReadOnly = false;
                    };
                  })
                  (
                    let
                      mkValuePairs = name: {
                        inherit name;
                        value = {
                          isReadOnly = false;
                        };
                      };
                      gpuBindMounts = lib.listToAttrs (lib.map mkValuePairs gpuDevices);
                    in
                    lib.mkIf containerConfig.gpuPassthrough gpuBindMounts
                  )
                  containerConfig.userMounts
                ];

                config = {
                  imports = [ "${inputs.self}/modules/nixos/system/nix-impl.nix" ];

                  modules.nixos.nix-impl = config.modules.nixos.nix-impl;

                  # Use systemd-resolved inside the container
                  # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
                  networking.useHostResolvConf = lib.mkForce false;
                  services.resolved.enable = true;

                  users.users."${cfg.user.name}" = {
                    inherit (cfg.user) uid group;
                    isSystemUser = true;
                  };

                  system.stateVersion = config.system.stateVersion;
                };
              };
          in
          lib.mapAttrs mkBaseConfig enabledContainers;

        addressConfigs =
          let
            sortedNames = lib.sort lib.lessThan (lib.attrNames enabledContainers);
            # Using imap1, index starts from 1
            mkValuePairs =
              index: name:
              let
                localIpv4 = utils.addToAddress cfg.bridge.ipv4.host index;
                localIpv6 = utils.addToAddress cfg.bridge.ipv6.host index;
              in
              {
                inherit name;
                value = {
                  hostBridge = cfg.bridge.name;
                  localAddress = "${localIpv4}/${builtins.toString cfg.bridge.ipv4.mask}";
                  localAddress6 = "${localIpv6}/${builtins.toString cfg.bridge.ipv6.mask}";

                  config = {
                    networking.defaultGateway = cfg.bridge.ipv4.host;
                  };
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
