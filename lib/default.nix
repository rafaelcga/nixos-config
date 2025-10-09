{ lib, ... }:
let
  # Function that returns all .nix files and modules (directories containing a
  # default.nix) in a given rootDir; can pass file or directory names to exclude.
  listNixPaths =
    {
      rootDir ? ./.,
      exclude ? [
        "default.nix"
        "extended-lib.nix"
      ],
    }:
    let
      isNixFile = { item, type }: (lib.hasSuffix ".nix" item) && (type == "regular");
      isModule =
        { item, type }: (builtins.pathExists (rootDir + "${item}/default.nix")) && (type == "directory");
    in
    (builtins.attrNames (
      lib.filterAttrs (
        item: type:
        (isNixFile { inherit item type; } || isModule { inherit item type; }) && !(lib.elem item exclude)
      ) (builtins.readDir rootDir)
    ));

  nixFileStems = builtins.map (fileName: lib.removeSuffix ".nix" fileName) (listNixPaths { });
  modules = lib.genAttrs nixFileStems (name: import ./${name}.nix { inherit lib; });
  moduleFunctions = lib.mergeAttrsList (lib.attrValues modules);
in
moduleFunctions // { inherit listNixPaths; } // modules # modules take precedence in merge
