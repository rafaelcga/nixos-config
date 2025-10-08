{ config, lib, ... }:
{
  nixpkgs.overlays = [
    (import ./catppuccin { inherit config lib; })
  ];
}
