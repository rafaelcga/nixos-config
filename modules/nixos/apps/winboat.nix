{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.winboat;
in
{
  options.modules.nixos.winboat = {
    enable = lib.mkEnableOption "Enable the WinBoat app";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker-compose
      winboat
    ];

    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };

    users.users."${userName}".extraGroups = [ "docker" ];

    hardware.nvidia-container-toolkit.enable = lib.elem "nvidia" config.modules.nixos.graphics.vendors;
  };
}
