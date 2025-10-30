{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.disko;

  mkDisk = disk: import "./${disk.type}.nix" { inherit (disk) name device; };
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.modules.nixos.disko = {
    disks = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Unique disko name";
            };
            device = lib.mkOption {
              type = lib.types.str;
              description = "Disk device identifier";
            };
            type = lib.mkOption {
              type = lib.types.str;
              description = "Disk type (see other .nix files in this module)";
            };
          };
        }
      );
      default = [ ];
      description = "List of attribute sets defining system disks";
    };
  };

  config = lib.mkMerge (map mkDisk cfg.disks);
}
