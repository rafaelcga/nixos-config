{
  config,
  lib,
  inputs,
  ...
}:
{
  nixpkgs.overlays = [
    (import ./catppuccin { inherit config lib inputs; })
    (final: prev: {
      local = (import "${inputs.self}/packages" { inherit config lib inputs; });
    })
  ];
}
