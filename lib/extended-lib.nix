inputs:
let
  inputLib =
    if builtins.hasAttr "home-manager" inputs then
      import "${inputs.home-manager}/modules/lib/stdlib-extended.nix" inputs.nixpkgs.lib
    else
      import inputs.nixpkgs.lib;
in
inputLib.extend (
  self: super: {
    local = import ./. { lib = self; };
  }
)
