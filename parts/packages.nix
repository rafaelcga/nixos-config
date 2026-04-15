{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      flakePkgs = import "${inputs.self}/pkgs" { inherit pkgs; };
    in
    {
      packages = flakePkgs.local // removeAttrs flakePkgs [ "local" ];
    };
}
