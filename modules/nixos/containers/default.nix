{
  inputs,
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers;
  user = config.users.users.${userName};

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  # `hostPath` is declared with default = null, so `hostPath or mountPoint`
  # would yield null instead of falling back to the mount point
  hostPathOf =
    mountPoint: mountConfig: if mountConfig.hostPath != null then mountConfig.hostPath else mountPoint;

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
  imports = [
    ./services
    ./backup.nix
  ];

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
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          modules = [ ./container-options.nix ];
          specialArgs = {
            inherit inputs;
            hostConfig = config;
          };
        }
      );
      default = { };
      description = "Enabled containers";
    };

    gpuDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/dev/dri/card0"
        "/dev/dri/renderD128"
      ];
      description = "List of available GPU devices";
    };
  };

  config = lib.mkIf (enabledContainers != { }) {
    boot.enableContainers = true;
    virtualisation = {
      containers.enable = true;
      podman.enable = true;
      oci-containers.backend = "podman";
    };

    networking = {
      nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = config.modules.nixos.networking.defaultInterface;
        internalInterfaces = [ cfg.bridge.name ];
      };

      # Prevent NetworkManager from managing container interfaces
      # https://nixos.org/manual/nixos/stable/#sec-container-networking
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [
          "interface-name:ve-*"
          "interface-name:${cfg.bridge.name}"
        ];
      };

      firewall.interfaces."${cfg.bridge.name}".allowedTCPPorts =
        let
          getOciPorts =
            _: containerConfig:
            if containerConfig.engine == "oci" then
              let
                ports = lib.attrValues containerConfig.hostPorts;
              in
              lib.filter (port: port != null) ports
            else
              [ ];
        in
        lib.unique (lib.concat (lib.mapAttrsToList getOciPorts enabledContainers));
    };

    users.users."${cfg.user.name}" = {
      inherit (cfg.user) uid group;
      isSystemUser = true;
      createHome = true;
      home = "${cfg.dataDir}/.container-home";
      linger = true;
      autoSubUidGidRange = true;
      extraGroups = [ "podman" ];
    };

    systemd =
      let
        withUserMounts = lib.filterAttrs (
          _: containerConfig: containerConfig.userMounts != { }
        ) enabledContainers;

        userMountPaths =
          let
            getHostPaths = userMounts: lib.mapAttrsToList hostPathOf userMounts;

            allUserMountPaths = lib.concatMap (containerConfig: getHostPaths containerConfig.userMounts) (
              lib.attrValues withUserMounts
            );
          in
          lib.unique allUserMountPaths;
      in
      {
        network = {
          enable = lib.mkDefault true;
          netdevs."20-${cfg.bridge.name}" = {
            netdevConfig = {
              Kind = "bridge";
              Name = cfg.bridge.name;
            };
          };
          networks."30-${cfg.bridge.name}" = {
            matchConfig.Name = cfg.bridge.name;
            networkConfig = {
              Address = "${cfg.bridge.ipv4.host}/${toString cfg.bridge.ipv4.mask}";
              ConfigureWithoutCarrier = true;
            };
            addresses = [
              {
                Address = "${cfg.bridge.ipv6.host}/${toString cfg.bridge.ipv6.mask}";
                DuplicateAddressDetection = "none";
              }
            ];
            linkConfig.RequiredForOnline = "no";
          };
        };

        services = lib.mkIf (withUserMounts != { }) {
          "setfacl-user-mounts" = rec {
            description = "Set the current and default ACL to rwX for user mounts";
            before =
              let
                getServiceName =
                  name: containerConfig:
                  if containerConfig.engine == "oci" then "podman-${name}.service" else "container@${name}.service";
              in
              lib.mapAttrsToList getServiceName withUserMounts;
            wantedBy = before;
            serviceConfig = {
              Type = "oneshot";
              ExecStart = lib.getExe (
                pkgs.writeShellApplication {
                  name = "setfacl-user-mounts";
                  runtimeInputs = with pkgs; [ acl ];
                  text = lib.concatMapStringsSep "\n" (mountPath: ''
                    setfacl -m g::rwX,d:g::rwX "${mountPath}"
                  '') userMountPaths;
                }
              );
            };
          };
        };

        tmpfiles.settings =
          let
            withDataDir = lib.filterAttrs (
              _: containerConfig: containerConfig.dataDir != null
            ) enabledContainers;
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
            "10-make-container-dirs" = lib.mapAttrs' settingTemplate withDataDir;
          };
      };

    containers =
      let
        mkBaseConfig = name: containerConfig: {
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

              # Get name of services from hostPorts present in containerPorts
              serviceNames = lib.attrNames (
                lib.intersectAttrs containerConfig.containerPorts containerConfig.hostPorts
              );
            in
            lib.concatMap mkForwardPort serviceNames;

          allowedDevices =
            let
              mkAllowedDevice = node: {
                inherit node;
                modifier = "rw";
              };
            in
            lib.mkIf containerConfig.gpuPassthrough (lib.map mkAllowedDevice cfg.gpuDevices);

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
                gpuBindMounts = lib.listToAttrs (lib.map mkValuePairs cfg.gpuDevices);
              in
              lib.mkIf containerConfig.gpuPassthrough gpuBindMounts
            )
            containerConfig.userMounts
          ];

          config = lib.mkMerge [
            {
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
            }
            (lib.mkIf containerConfig.gpuPassthrough {
              imports = [ "${inputs.self}/modules/nixos/hardware/graphics.nix" ];

              _module.args.userName = cfg.user.name;
              modules.nixos.graphics = config.modules.nixos.graphics;
            })
          ];
        };

        mkAddressConfig = name: containerConfig: {
          hostBridge = cfg.bridge.name;
          localAddress = "${containerConfig.address}/${toString cfg.bridge.ipv4.mask}";
          localAddress6 = "${containerConfig.address6}/${toString cfg.bridge.ipv6.mask}";

          config = {
            systemd.network = {
              enable = true;
              networks."10-bridge" = {
                matchConfig.Name = "eth0";
                networkConfig = {
                  Address = config.containers.${name}.localAddress;
                  Gateway = cfg.bridge.ipv4.host;
                };
                addresses = [
                  {
                    Address = config.containers.${name}.localAddress6;
                    DuplicateAddressDetection = "none";
                  }
                ];
                linkConfig.RequiredForOnline = "routable";
              };
            };
          };
        };

        nspawnContainers =
          let
            isNspawn = _: containerConfig: containerConfig.engine == "nspawn";
          in
          lib.filterAttrs isNspawn enabledContainers;
      in
      lib.mkMerge [
        (lib.mapAttrs mkBaseConfig nspawnContainers)
        (lib.mapAttrs mkAddressConfig nspawnContainers)
      ];

    virtualisation.oci-containers.containers =
      let
        mkOciConfig = name: containerConfig: {
          inherit (containerConfig) image;

          podman.user = cfg.user.name;

          ports =
            let
              serviceNames = lib.filter (
                serviceName:
                containerConfig.hostPorts.${serviceName} != null
                && containerConfig.containerPorts.${serviceName} != null
              ) (lib.attrNames (lib.intersectAttrs containerConfig.containerPorts containerConfig.hostPorts));
              mkPort =
                serviceName:
                "${containerConfig.address}:${toString containerConfig.hostPorts.${serviceName}}:${
                  toString containerConfig.containerPorts.${serviceName}
                }";
            in
            lib.map mkPort serviceNames;

          volumes =
            (lib.optionals (containerConfig.dataDir != null) [
              "${cfg.dataDir}/${name}:${containerConfig.dataDir}"
            ])
            ++ (lib.mapAttrsToList (
              mountPoint: mountConfig:
              "${hostPathOf mountPoint mountConfig}:${mountPoint}${lib.optionalString mountConfig.isReadOnly ":ro"}"
            ) containerConfig.userMounts);
        };

        ociContainers =
          let
            isOci = _: containerConfig: containerConfig.engine == "oci";
          in
          lib.filterAttrs isOci enabledContainers;
      in
      lib.mapAttrs mkOciConfig ociContainers;
  };
}
