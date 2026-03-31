{ pkgs }:
{
  caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins/package.nix { };
  papermc = pkgs.callPackage ./papermc/package.nix { };
  unmanic = pkgs.callPackage ./unmanic/package.nix { };
  cachyos-settings = pkgs.callPackage ./cachyos-settings.nix { };
  crowdsec = pkgs.callPackage ./crowdsec.nix { };
}
