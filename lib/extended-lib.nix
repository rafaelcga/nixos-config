# Extends home-manager.lib (or nixpkgs.lib) with local lib; similar
# to github:nix-community/home-manager/blob/master/modules/lib/stdlib-extended.nix
inputs:
let
  inputLib =
    if builtins.hasAttr "home-manager" inputs then
      import "${inputs.home-manager}/modules/lib/stdlib-extended.nix" inputs.nixpkgs.lib
    else
      import inputs.nixpkgs.lib;
in
# Get fully extended lib into local lib passing self
inputLib.extend (
  self: super: {
    local = import ./. { lib = self; };
  }
)
