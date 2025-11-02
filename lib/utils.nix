{ lib, ... }:
let
  upperFirst = str: lib.toUpper (lib.substring 0 1 str);
  lowerOther = str: lib.toLower (lib.substring 1 (lib.stringLength str - 1) str);
in
{
  capitalizeFirst = str: if str == "" then "" else upperFirst str + lowerOther str;

  listSubdirs =
    path:
    let
      dirContents = lib.readDir path;
    in
    lib.attrNames (lib.filterAttrs (_: type: type == "directory") dirContents);
}
