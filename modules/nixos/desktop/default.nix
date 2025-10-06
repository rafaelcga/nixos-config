{ config, lib, ... }:
let
  cfg = config.modules.nixos.desktop;
in
{
  imports = [
    ./gnome
  ];

  options.modules.nixos.desktop = {
    enable = lib.mkEnableOption "Desktop Environment configuration";
    environment = lib.mkOption {
      default = "gnome";
      type = lib.types.enum [
        "gnome"
      ];
      description = ''
        Desktop environment to use. Supported values:
        - "gnome"
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    modules.nixos.desktop.${cfg.environment}.enable = true;
  };
}
