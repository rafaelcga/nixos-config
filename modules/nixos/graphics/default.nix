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
  extraPackages = lib.concatLists (
    builtins.map (
      vendor: if builtins.hasAttr vendor vendorPackages then vendorPackages.${vendor} else [ ]
    ) cfg.vendors
  );
  usesNvidia = builtins.elem "nvidia" cfg.vendors;
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
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
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
