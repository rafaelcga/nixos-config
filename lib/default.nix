{ lib, ... }:
let
  # Function that returns all .nix files and modules (directories containing a
  # default.nix) in a given rootDir; can pass file or directory names to exclude.
  listNixModules =
    {
      rootDir,
      exclude ? [
        "default.nix"
        "extended-lib.nix"
      ],
    }:
    let
      allItems = builtins.readDir rootDir;
      isNixFile = { item, type }: (lib.hasSuffix ".nix" item) && (type == "regular");
      isModule =
        { item, type }: (builtins.pathExists "${rootDir}/${item}/default.nix") && (type == "directory");
      fileFilter =
        item: type:
        (isNixFile { inherit item type; } || isModule { inherit item type; }) && !(lib.elem item exclude);
    in
    (builtins.attrNames (lib.filterAttrs fileFilter allItems));
  # Wrapper to return absolute paths
  listNixPaths =
    {
      rootDir,
      exclude ? [
        "default.nix"
        "extended-lib.nix"
      ],
    }:
    let
      nixModules = listNixModules { inherit rootDir exclude; };
    in
    (builtins.map (module: rootDir + "/${module}") nixModules);

  # Import functions and make them available at a higher scope
  nixFileNames = listNixModules { rootDir = ./.; };
  nixFileStems = builtins.map (fileName: lib.removeSuffix ".nix" fileName) nixFileNames;
  modules = lib.genAttrs nixFileStems (stem: import ./${stem}.nix { inherit lib; });
  moduleFunctions = lib.mergeAttrsList (lib.attrValues modules);
in
moduleFunctions // { inherit listNixPaths; } // modules # modules take precedence in merge
