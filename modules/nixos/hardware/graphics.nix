{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.graphics;

  vendorPackages = with pkgs; {
    intel = [
      intel-ocl
      vpl-gpu-rt
      intel-media-driver
      intel-compute-runtime
    ]
    ++ lib.optionals cfg.enable32Bit [
      driversi686Linux.intel-media-driver
    ];
    amd = [ ];
    nvidia = [ ];
  };
  extraPackages = lib.concatMap (vendor: vendorPackages.${vendor}) cfg.vendors;
in
{
  options.modules.nixos.graphics = {
    enable = lib.mkEnableOption "Enable graphics";

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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        hardware = {
          enableAllFirmware = !config.boot.isContainer; # Enables all firmware regardless of license
          graphics = lib.mkDefault {
            inherit (cfg) enable enable32Bit;
            inherit extraPackages;
          };
        };
        nixpkgs.config.allowUnfree = lib.mkForce true; # Required for firmware

        users.users.${userName}.extraGroups = [
          "video"
          "render"
        ];
      }
      (lib.mkIf (lib.elem "intel" cfg.vendors) {
        boot.kernelParams = lib.mkIf (!config.boot.isContainer) [ "i915.enable_guc=3" ];
        services.xserver.videoDrivers = lib.mkIf (!config.boot.isContainer) [ "modesetting" ];
        environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
      })
      (lib.mkIf (lib.elem "amd" cfg.vendors && !config.boot.isContainer) {
        services.xserver.videoDrivers = [ "amdgpu" ];
      })
      (lib.mkIf (lib.elem "nvidia" cfg.vendors && !config.boot.isContainer) {
        hardware.nvidia = {
          open = true; # Open-source kernel module
          modesetting.enable = true;
        };
        services.xserver.videoDrivers = [ "nvidia" ];
        boot.initrd.availableKernelModules = [
          "nvidia_drm"
          "nvidia_modeset"
          "nvidia"
          "nvidia_uvm"
        ];

        nixpkgs.config.cudaSupport = true; # Global package override
        nix.settings = {
          substituters = [ "https://cache.nixos-cuda.org" ];
          trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
        };
      })
    ]
  );
}
