{ inputs, ... }@args:
{
  nixpkgs.overlays = [
    (import ./catppuccin args)
    (final: prev: {
      local = (import "${inputs.self}/packages" (args // { pkgs = final; }));
    })
  ];
}
