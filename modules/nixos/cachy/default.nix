{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.cachy;
in
{
  options.modules.nixos.cachy = {
    enable = lib.mkEnableOption "Cachy kernel and optimizations configuration";
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos;
    environment.systemPackages = [ pkgs.ananicy-rules-cachyos ];
  };
}
