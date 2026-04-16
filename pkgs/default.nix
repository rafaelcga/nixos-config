{
  pkgs,
  prev ? pkgs,
}:
let
  inherit (prev) lib;

  callPackage =
    {
      name,
      isOverride ? false,
    }:
    pkgs.callPackage ./${name}/package.nix (lib.optionalAttrs isOverride { "${name}" = prev.${name}; });

  mkPackages =
    {
      derivations ? [ ],
      overrides ? [ ],
    }:
    (lib.genAttrs derivations (
      name:
      callPackage {
        inherit name;
        isOverride = false;
      }
    ))
    // (lib.genAttrs overrides (
      name:
      callPackage {
        inherit name;
        isOverride = true;
      }
    ));
in
{
  local = mkPackages {
    derivations = [
      "cachyos-settings"
      "caddy-with-plugins"
      "unmanic"
    ];
  };
}
// mkPackages {
  derivations = [
    "crowdsec" # TODO: use overrideAttrs when PR merges
  ];
  overrides = [
    "catppuccin-papirus-folders"
    "flatpak"
    "jellyfin-ffmpeg"
    "papirus-folders"
    "papirus-icon-theme"
  ];
}
