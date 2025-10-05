{ nixpkgs, ... }:
let
  functions = builtins.map (fn: import fn { inherit nixpkgs; }) [ ./capitalize-first.nix ];
in
nixpkgs.lib.mergeAttrsList functions
