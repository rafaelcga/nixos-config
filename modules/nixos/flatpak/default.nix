{ config, lib, ... }:
let
  cfg = config.modules.nixos.flatpak;
in
{
  options.modules.nixos.flatpak = {
    enable = lib.mkEnableOption "Flatpak configuration";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
