args@{ inputs, ... }:
{
  nixpkgs.overlays = [
    (import ./catppuccin.nix args)
    (import ./homepage-dashboard.nix)
    (
      final: prev:
      import "${inputs.self}/pkgs" {
        pkgs = final;
        inherit prev;
      }
    )
  ];
}
