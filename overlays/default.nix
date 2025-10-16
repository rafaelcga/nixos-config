{
  config,
  lib,
  inputs,
  ...
}:
{
  nixpkgs.overlays = [
    (import ./catppuccin { inherit config lib inputs; })
  ];
}
