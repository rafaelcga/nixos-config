{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.flatpak;
  inherit (config.modules.nixos) fonts;
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
      packages = [
        "io.github.kolunmi.Bazaar"
        "com.github.tchx84.Flatseal"
      ]
      ++ cfg.packages;

      overrides = {
        writeMode = "replace";
        pruneUnmanagedOverrides = true;

        settings.global.Context.filesystems = [
          "~/.icons:ro"
          "~/.local/share/icons:ro"
          "/nix/store:ro"
        ]
        ++ lib.optionals fonts.enable [
          "~/.fonts:ro"
          "~/.local/share/fonts:ro"
        ];
      };
    };
  };
}
