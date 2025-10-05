{ nixpkgs, ... }:
let
  inherit (nixpkgs.lib) toUpper toLower;
  upperFirst = string: toUpper (builtins.substring 0 1 string);
  lowerOther = string: toLower (builtins.substring 1 (builtins.stringLength string - 1) string);
in
{
  capitalizeFirst = string: if string == "" then "" else upperFirst string + lowerOther string;
}
