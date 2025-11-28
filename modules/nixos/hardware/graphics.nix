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
          enableAllFirmware = true; # Enables all firmware regardless of license
          graphics = {
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
        boot.kernelParams = [ "i915.enable_guc=3" ];
        services.xserver.videoDrivers = [ "modesetting" ];
        environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
      })
      (lib.mkIf (lib.elem "amd" cfg.vendors) {
        services.xserver.videoDrivers = [ "amdgpu" ];
      })
      (lib.mkIf (lib.elem "nvidia" cfg.vendors) {
        hardware.nvidia = {
          open = true; # Open-source kernel module
          package = config.boot.kernelPackages.nvidiaPackages.latest;
        };
        services.xserver.videoDrivers = [ "nvidia" ];
      })
    ]
  );
}
