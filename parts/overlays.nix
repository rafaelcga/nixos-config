args@{ inputs, ... }:
{
  flake.overlays.default = import "${inputs.self}/overlays" args;

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.self.overlays.default ];
        config.allowUnfree = true;
      };
    };
}
