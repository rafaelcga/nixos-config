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

  enabledContainers = lib.filterAttrs (_: containerConfig: containerConfig.enable) cfg.services;
  withEngine =
    engine: lib.filterAttrs (_: containerConfig: containerConfig.engine == engine) enabledContainers;
  nspawnContainers = withEngine "nspawn";
  ociContainers = withEngine "oci";

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

    lanSubnets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        config.modules.nixos.home-vpn.network.subnet
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];
      description = "IPv4 subnets considered local: allowed to query DNS and bypassing the VPN";
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
    # Container IPs are derived from `uid`, so a duplicate would silently collide
    assertions =
      let
        uids = lib.mapAttrsToList (_: containerConfig: containerConfig.uid) cfg.services;
        duplicates = lib.unique (lib.filter (uid: lib.count (other: other == uid) uids > 1) uids);
      in
      [
        {
          assertion = duplicates == [ ];
          message = "modules.nixos.containers: duplicate container uids: ${toString duplicates}";
        }
      ];

    boot.enableContainers = true;
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        autoPrune = {
          enable = true;
          flags = [ "--all" ];
        };
      };
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

      # Open ports of OCI containers to the bridge
      firewall.interfaces =
        let
          uniqueOciPorts = lib.unique (
            lib.concatMap (containerConfig: map (mapping: mapping.hostPort) containerConfig.portMappings) (
              lib.attrValues ociContainers
            )
          );
        in
        {
          "${config.modules.nixos.networking.defaultInterface}".allowedTCPPorts = uniqueOciPorts;
          "${cfg.bridge.name}".allowedTCPPorts = uniqueOciPorts;
        };
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

        userMountPaths = lib.unique (
          lib.concatMap (
            containerConfig: lib.mapAttrsToList (_: mount: mount.hostPath) containerConfig.userMounts
          ) (lib.attrValues withUserMounts)
        );
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

        services = lib.mkMerge [
          # `pull = "newer"` only pulls when a container starts, so restart them
          # daily to pick up new images. (`podman auto-update` would need
          # per-container labels and a rootless timer per user.)
          (lib.mkIf (ociContainers != { }) {
            "podman-update-images" = {
              description = "Restart OCI containers to pull newer images";
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${config.systemd.package}/bin/systemctl try-restart ${
                  lib.concatMapStringsSep " " (name: "podman-${name}.service") (lib.attrNames ociContainers)
                }";
              };
            };
          })
          (lib.mkIf (withUserMounts != { }) {
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
          })
        ];

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

        timers."podman-update-images" = lib.mkIf (ociContainers != { }) {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 05:00:00";
            RandomizedDelaySec = "30m";
            Persistent = true;
          };
        };
      };

    containers =
      let
        mkNspawnConfig = name: containerConfig: {
          autoStart = true;
          privateNetwork = true;
          privateUsers = "identity";

          hostBridge = cfg.bridge.name;
          localAddress = "${containerConfig.address}/${toString cfg.bridge.ipv4.mask}";
          localAddress6 = "${containerConfig.address6}/${toString cfg.bridge.ipv6.mask}";

          forwardPorts = map (mapping: {
            inherit (mapping) hostPort containerPort;
          }) containerConfig.portMappings;

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
            }
            (lib.mkIf containerConfig.gpuPassthrough {
              imports = [ "${inputs.self}/modules/nixos/hardware/graphics.nix" ];

              _module.args.userName = cfg.user.name;
              modules.nixos.graphics = config.modules.nixos.graphics;
            })
          ];
        };
      in
      lib.mapAttrs mkNspawnConfig nspawnContainers;

    virtualisation.oci-containers.containers =
      let
        mkOciConfig = name: containerConfig: {
          inherit (containerConfig) image environment;

          podman.user = cfg.user.name;
          pull = "newer";

          ports = map (
            mapping: "0.0.0.0:${toString mapping.hostPort}:${toString mapping.containerPort}"
          ) containerConfig.portMappings;

          volumes =
            (lib.optionals (containerConfig.dataDir != null) [
              "${cfg.dataDir}/${name}:${containerConfig.dataDir}"
            ])
            ++ (lib.mapAttrsToList (
              mountPoint: mountConfig:
              "${mountConfig.hostPath}:${mountPoint}${lib.optionalString mountConfig.isReadOnly ":ro"}"
            ) containerConfig.userMounts);
        };
      in
      lib.mapAttrs mkOciConfig ociContainers;
  };
}
