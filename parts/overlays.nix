{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          # TODO: Import overlays
          (final: _: {
            local = import "${inputs.self}/pkgs" {
              inherit (inputs.nixpkgs) lib;
              pkgs = final;
            };
          })
        ];
        config = {
          allowUnfree = true;
        };
      };
    };
}
