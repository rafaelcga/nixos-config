args@{ inputs, lib, ... }:
{
  nixpkgs.overlays = [
    (import ./catppuccin.nix args)
    (final: prev: {
      local = import "${inputs.self}/pkgs" {
        inherit lib;
        pkgs = final;
      };
    })
  ];
}
