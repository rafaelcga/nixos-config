{ config, lib, ... }:
{
  nixpkgs.overlays = [
    (import ./catppuccin-kde { inherit config lib; })
  ];
}
