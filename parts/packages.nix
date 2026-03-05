{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = import "${inputs.self}/pkgs" { inherit lib pkgs; };
    };
}
