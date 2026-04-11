{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.papirus;
in
{
  options.modules.nixos.papirus = {
    enable = lib.mkEnableOption "Enable Papirus Icon Theme";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.papirus-icon-theme;
      description = "Icon package";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.icons.enable = true; # Links icons to home using XDG specification

    environment.systemPackages = [ cfg.package ];

    home-manager.users.${userName} = {
      gtk = {
        enable = true;
        iconTheme = {
          name = lib.mkDefault "Papirus";
          package = lib.mkForce cfg.package;
        };
      };
    };
  };
}
