{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.graphics;
  vendorPackages = with pkgs; {
    "intel" = [
      intel-media-driver
      driversi686Linux.intel-media-driver # 32-bit
      intel-compute-runtime
      vpl-gpu-rt
    ];
  };
in
{
  options.modules.nixos.graphics = {
    enable = lib.mkEnableOption "graphics configuration";
    vendors = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (
        lib.types.enum [
          "intel"
          "amd"
          "nvidia"
        ]
      );
      description = ''
        List of one or more GPU vendors in the system. Supported values:
        - "intel"
        - "amd"
        - "nvidia"
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = lib.concatLists (builtins.map (vendor: vendorPackages.${vendor}) cfg.vendors);
      nvidia = lib.mkIf (builtins.elem "nvidia" cfg.vendors) {
        open = true; # Open-source kernel module
        package = config.boot.kernelPackages.nvidiaPackages.latest;
      };
    };
    services.xserver = lib.mkIf (builtins.elem "nvidia" cfg.vendors) {
      videoDrivers = [ "nvidia" ];
    };
  };
}
