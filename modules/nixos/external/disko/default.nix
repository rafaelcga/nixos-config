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
      type = lib.mkOption {
        type = lib.types.str;
        description = "Disk type (see other .nix files in this module)";
      };
    };
  };

  mkDiskConfig = name: disk: import ./${disk.type}.nix { inherit (disk) device; };
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
