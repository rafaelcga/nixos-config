{ inputs, ... }:
{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages = import "${inputs.self}/pkgs" { inherit lib pkgs; };
    };
}
