{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.disko;

  mkDisk =
    name: config:
    let
      inherit (config)
        device
        format
        mountpoint
        isBootable
        destroy
        ;
      partitionName = if mountpoint == "/" then "root" else name;
      partitionTemplates = {
        efi = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = config.boot.loader.efi.efiSysMountPoint;
            mountOptions = [ "umask=0077" ];
          };
        };
        ext4 = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            inherit mountpoint;
          };
        };
      };
    in
    {
      inherit device destroy;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = lib.mkIf isBootable partitionTemplates.efi;
          "${partitionName}" = partitionTemplates.${format};
        };
      };
    };

  diskOpts = {
    options = {
      device = lib.mkOption {
        type = lib.types.str;
        description = "Disk device identifier";
      };

      format = lib.mkOption {
        type = lib.types.enum [ "ext4" ];
        description = "Format of the main partition";
      };

      mountpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "/";
        description = "Mountpoint of the main partition";
      };

      isBootable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the disk has the /boot partition";
      };

      destroy = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          If false, disko will not wipe or destroy this disk's contents
          during the destroy stage
        '';
      };
    };
  };

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
    disko.devices.disk = lib.mapAttrs mkDisk cfg.disks;
  };
}
