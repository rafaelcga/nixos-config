{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.desktop.cosmic;
in
{
  options.modules.nixos.desktop.cosmic = {
    enable = lib.mkEnableOption "COSMIC dektop configuration";
  };

  config = lib.mkIf cfg.enable {
    services = {
      desktopManager.cosmic.enable = true;
      displayManager.cosmic-greeter.enable = true;
    };
    environment.systemPackages = with pkgs; [
      papers
      celluloid
    ];
  };
}
