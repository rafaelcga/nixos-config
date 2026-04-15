{
  pkgs,
  prev ? pkgs,
}:
let
  mkOverride = name: pkgs.callPackage ./${name}.nix { "${name}" = prev.${name}; };
  mkOverrideCustom = name: pkgs.callPackage ./${name}/package.nix { "${name}" = prev.${name}; };
in
{
  local = {
    caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins/package.nix { };
    unmanic = pkgs.callPackage ./unmanic/package.nix { };
    cachyos-settings = pkgs.callPackage ./cachyos-settings.nix { };
  };

  crowdsec = pkgs.callPackage ./crowdsec.nix { }; # TODO: use overrideAttrs when PR merges
}
// (prev.lib.genAttrs [
  "flatpak"
  "jellyfin-ffmpeg"
  "papirus-folders"
] mkOverride)
// (prev.lib.genAttrs [
  "catppuccin-papirus-folders"
  "papirus-icon-theme"
] mkOverrideCustom)
