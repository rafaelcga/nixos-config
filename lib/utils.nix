{ lib, ... }:
{
  listSubdirs =
    path:
    let
      dirContents = builtins.readDir path;
    in
    lib.attrNames (lib.filterAttrs (_: type: type == "directory") dirContents);
}
