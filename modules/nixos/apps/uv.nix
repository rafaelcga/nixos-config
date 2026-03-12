{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.uv;
in
{
  options.modules.nixos.uv = {
    enable = lib.mkEnableOption "Enable the uv Python package manager";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ uv ];
      localBinInPath = true; # adds ~/.local/bin/ to $PATH for uv tool
    };

    programs.nix-ld = {
      enable = true;
      libraries =
        config.hardware.graphics.extraPackages
        # Link CUDA libraries
        ++ lib.optionals (lib.elem "nvidia" config.services.xserver.videoDrivers) [
          config.hardware.nvidia.package
        ];
    };
  };
}
