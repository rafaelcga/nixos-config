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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Only enable the selected environment
      (lib.mkIf (cfg.environment == "gnome") {
        modules.nixos.desktop.gnome.enable = true;
      })
      # Add more environments here
      # (lib.mkIf (cfg.environment == "kde") {
      #   modules.nixos.desktop.kde.enable = true;
      # })
    ]
  );
}
