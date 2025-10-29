{ inputs, ... }:
{
  perSystem =
    { ... }:
    {
      packages = import "${inputs.self}/pkgs";
    };
}
