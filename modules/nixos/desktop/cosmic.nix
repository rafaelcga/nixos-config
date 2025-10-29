{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.cosmic;
in
{
  imports = [ ];

  options.modules.nixos.cosmic = {
    enable = lib.mkEnableOption "Enable COSMIC Desktop Environment";
  };

  config = lib.mkIf cfg.enable {
    services = {
      displayManager.cosmic-greeter.enable = true;
      desktopManager.cosmic.enable = true;
    };

    programs.partition-manager.enable = true;
    environment = {
      cosmic.excludePackages = with pkgs; [
        cosmic-term
        cosmic-player
      ];
      systemPackages = with pkgs; [
        loupe
        papers
        ghostty
        celluloid
        gnome-calendar
      ];
      sessionVariables.NIXOS_OZONE_WL = "1"; # Hint Electron apps to use Wayland
    };
  };
}
