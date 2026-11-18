{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.flatpak;
  inherit (config.modules.nixos) fonts;

  packages = [
    "io.github.kolunmi.Bazaar"
    "com.github.tchx84.Flatseal"
  ]
  ++ cfg.packages;

  # Electron apps whose Flatpak manifest lacks the Wayland socket. Without it
  # they run on Xwayland, which is blurry on fractional scales.
  electronApps = [ "com.discordapp.Discord" ];
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
      update.onActivation = true;

      inherit packages;

      overrides = {
        writeMode = "replace";
        pruneUnmanagedOverrides = true;

        settings = {
          global = {
            Context.filesystems = [
              "~/.icons:ro"
              "~/.local/share/icons:ro"
              "/nix/store:ro"
            ]
            ++ lib.optionals fonts.enable [ "~/.local/share/fonts:ro" ];

            # Flatpak equivalent of NIXOS_OZONE_WL, which only nixpkgs wrappers
            # read: Electron < 38 picks Wayland when its socket is available
            # (newer versions do so by default)
            Environment.ELECTRON_OZONE_PLATFORM_HINT = "auto";
          };
        }
        // lib.genAttrs (lib.intersectLists electronApps packages) (_: {
          # X11 is kept as fallback
          Context.sockets = [ "wayland" ];
        });
      };
    };
  };
}
