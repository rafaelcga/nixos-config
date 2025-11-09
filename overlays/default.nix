args@{ inputs, ... }:
{
  nixpkgs.overlays = [
    (import ./catppuccin.nix args)
    (final: prev: {
      local = final.callPackage "${inputs.self}/pkgs" { };
    })
  ];
}
