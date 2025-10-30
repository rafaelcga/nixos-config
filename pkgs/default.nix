{ pkgs }:
{
  caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins/package.nix { };
  cachyos-settings = pkgs.callPackage ./cachyos-settings.nix { };
}
