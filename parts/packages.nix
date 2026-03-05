{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = import "${inputs.self}/pkgs" { inherit pkgs; };
    };
}
