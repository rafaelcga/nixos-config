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
      intel-compute-runtime
      vpl-gpu-rt
    ];
    "amd" = [ ];
    "nvidia" = [ ];
  };
  vendorPackages32Bit = with pkgs; {
    "intel" = [ driversi686Linux.intel-media-driver ];
    "amd" = [ ];
    "nvidia" = [ ];
  };
  extraPackages = lib.concatLists (
    builtins.map (
      vendor: vendorPackages.${vendor} ++ (if cfg.enable32Bit then vendorPackages32Bit.${vendor} else [ ])
    ) cfg.vendors
  );
  usesNvidia = builtins.elem "nvidia" cfg.vendors;
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
        forceFullCompositionPipeline = true;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
      };
    };
    services.xserver = lib.mkIf usesNvidia {
      videoDrivers = [ "nvidia" ];
    };
  };
}
