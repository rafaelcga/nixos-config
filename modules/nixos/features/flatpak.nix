{
  inputs,
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.flatpak;
  user = config.users.users.${userName};
in
{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  options.modules.nixos.flatpak = {
    enable = lib.mkEnableOption "Enable Flatpak support using nix-flatpak";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Flatpak packages to install";
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak = {
      enable = true;
      inherit (cfg) packages;
      overrides.global = {
        Environment.GSK_RENDERER = "gl"; # fixes graphical flatpak bug under Wayland
        Context.filesystems = [
          "${user.home}/.local/share/fonts:ro"
          "${user.home}/.local/share/icons:ro"
          "/nix/store:ro"
        ];
      };
    };
  };
}
