{ lib, ... }@args:
let
  libExclude = [
    "default.nix"
    "extended-lib.nix"
  ];

  # Function that returns all .nix files and modules (directories containing a
  # default.nix) in a given rootDir; can pass file or directory names to exclude.
  listNixModules =
    {
      rootDir,
      exclude ? [ "default.nix" ],
    }:
    let
      isNixFile = { item, type }: (lib.hasSuffix ".nix" item) && (type == "regular");
      isModule =
        { item, type }: (builtins.pathExists "${rootDir}/${item}/default.nix") && (type == "directory");
      fileFilter =
        item: type:
        (isNixFile { inherit item type; } || isModule { inherit item type; }) && !(lib.elem item exclude);
    in
    (builtins.attrNames (lib.filterAttrs fileFilter (builtins.readDir rootDir)));

  # Wrapper to return absolute paths
  listNixPaths =
    {
      rootDir,
      exclude ? [ "default.nix" ],
    }:
    let
      nixModules = listNixModules { inherit rootDir exclude; };
    in
    (builtins.map (module: "${rootDir}/${module}") nixModules);

  # Function to import modules
  importModules =
    {
      rootDir,
      callArgs ? { },
      exclude ? [ "default.nix" ],
    }:
    let
      nixFileNames = listNixModules { inherit rootDir exclude; };
      nixFileStems = builtins.map (fileName: lib.removeSuffix ".nix" fileName) nixFileNames;
    in
    (lib.genAttrs nixFileStems (stem: import ./${stem}.nix callArgs));

  # Import functions and make them available at a higher scope
  modules = importModules {
    rootDir = ./.;
    callArgs = args;
    exclude = libExclude;
  };
  moduleFunctions = lib.mergeAttrsList (lib.attrValues modules);
in
moduleFunctions // { inherit listNixPaths; } // modules # modules take precedence in merge
