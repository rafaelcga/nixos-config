args@{ inputs, ... }:
{
  nixpkgs.overlays = [
    (import ./catppuccin.nix args)
    (import ./homepage-dashboard.nix args)
    (final: prev: {
      local = import "${inputs.self}/pkgs" { pkgs = final; };
    })
  ];
}
