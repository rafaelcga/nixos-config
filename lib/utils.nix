{ lib, ... }:
let
  upperFirst = str: lib.toUpper (builtins.substring 0 1 str);
  lowerOther = str: lib.toLower (builtins.substring 1 (builtins.stringLength str - 1) str);
in
{
  capitalizeFirst = str: if str == "" then "" else upperFirst str + lowerOther str;

  listSubdirs =
    path:
    let
      dirContents = builtins.readDir path;
    in
    lib.attrNames (lib.filterAttrs (_: type: type == "directory") dirContents);
}
