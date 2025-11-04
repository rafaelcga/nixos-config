{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.disko;

  diskOpts = {
    options = {
      device = lib.mkOption {
        type = lib.types.str;
        description = "Disk device identifier";
      };

      destroy = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "If false, disko will not wipe or destroy this disk's contents during the destroy stage";
      };

      mountpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Mountpoint of the main partition in the disk type";
      };

      type = lib.mkOption {
        type = lib.types.str;
        description = "Disk type (see other .nix files in this module)";
      };
    };
  };

  mkDiskConfig = name: disk: import ./${disk.type}.nix (lib.removeAttrs disk [ "type" ]);
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.modules.nixos.disko = {
    disks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule diskOpts);
      default = { };
      description = "Attribute set defining system disks";
    };
  };

  config = {
    disko.devices.disk = lib.mapAttrs mkDiskConfig cfg.disks;
  };
}
