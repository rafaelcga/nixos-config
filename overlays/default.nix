args@{ inputs, ... }:
{
  nixpkgs.overlays = [
    (import ./catppuccin.nix args)
    (import ./homepage-dashboard.nix)
    (final: prev: {
      local = import "${inputs.self}/pkgs" { pkgs = final; };
    })
  ];
}
