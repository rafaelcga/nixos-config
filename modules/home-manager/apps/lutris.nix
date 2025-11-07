{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (osConfig.programs) steam;
  cfg = config.modules.home-manager.lutris;
in
{
  options.modules.home-manager.lutris = {
    enable = lib.mkEnableOption "Toggle module";
  };

  config = lib.mkIf cfg.enable {
    programs.lutris = {
      enable = true;
      steamPackage = lib.mkIf steam.enable steam.package;
      extraPackages = with pkgs; [ umu-launcher ];
    };
  };
}
