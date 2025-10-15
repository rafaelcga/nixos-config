{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.graphics;
  usesNvidia = builtins.elem "nvidia" cfg.vendors;

  vendorPackages = with pkgs; {
    "intel" = [
      intel-ocl
      vpl-gpu-rt
      intel-media-driver
      intel-compute-runtime
    ]
    ++ lib.optionals cfg.enable32Bit [
      driversi686Linux.intel-media-driver
    ];
    "amd" = [ ];
    "nvidia" = [ ];
  };
  extraPackages = lib.concatLists (builtins.map (vendor: vendorPackages.${vendor}) cfg.vendors);
in
{
  options.modules.nixos.graphics = {
    enable = lib.mkEnableOption "graphics configuration";
    enable32Bit = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Whether to enable 32-bit drivers";
    };
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
    hardware = {
      graphics = {
        enable = true;
        inherit (cfg) enable32Bit;
        inherit extraPackages;
      };
      nvidia = lib.mkIf usesNvidia {
        open = true; # Open-source kernel module
        package = config.boot.kernelPackages.nvidiaPackages.latest;
      };
    };
    services.xserver = lib.mkIf usesNvidia {
      videoDrivers = [ "nvidia" ];
    };
  };
}
