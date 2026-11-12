{
  pkgs,
  prev ? pkgs,
}:
let
  inherit (prev) lib;

  callPackage = name: args: pkgs.callPackage ./${name}/package.nix args;
in
{
  # New packages, exposed as `pkgs.local.<name>`
  local = lib.genAttrs [
    "cachyos-settings"
    "caddy-with-plugins"
    "unmanic"
  ] (name: callPackage name { });
}
# Overrides of nixpkgs packages; each gets the original as its `<name>` argument
// lib.genAttrs [
  "catppuccin-papirus-folders"
  "papirus-icon-theme"
] (name: callPackage name { ${name} = prev.${name}; })
