{ inputs, lib, ... }:
final: prev: {
  local = import "${inputs.self}/pkgs" {
    inherit lib;
    pkgs = final;
  };
}
