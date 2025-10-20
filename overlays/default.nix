{ lib, inputs, ... }@args:
{
  nixpkgs.overlays = [
    (import ./catppuccin args)
    (final: prev: {
      local = lib.local.callPackages {
        rootDir = "${inputs.self}/pkgs";
        pkgs = final;
      };
    })
  ];
}
