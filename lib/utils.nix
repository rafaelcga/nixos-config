{ lib, ... }:
let
  upperFirst = string: lib.toUpper (builtins.substring 0 1 string);
  lowerOther = string: lib.toLower (builtins.substring 1 (builtins.stringLength string - 1) string);
in
rec {
  capitalizeFirst = string: if string == "" then "" else upperFirst string + lowerOther string;

  # Returns all .nix files and modules (directories containing a default.nix) in
  # a given rootDir; can pass file or directory names to exclude
  listNixModules =
    {
      rootDir,
      exclude ? [ "default.nix" ],
    }:
    let
      dirContent = builtins.readDir rootDir;
      isModule =
        name: type:
        let
          isNixFile = lib.hasSuffix ".nix" name && type == "regular";
          isDirModule = type == "directory" && builtins.pathExists "${rootDir}/${name}/default.nix";
        in
        isNixFile || isDirModule;
    in
    lib.attrNames (
      lib.filterAttrs (name: type: isModule name type && !(lib.elem name exclude)) dirContent
    );

  # Returns absolute paths of modules in given root directory
  listNixPaths =
    {
      rootDir,
      exclude ? [ "default.nix" ],
    }:
    let
      nixModules = listNixModules { inherit rootDir exclude; };
    in
    map (module: "${rootDir}/${module}") nixModules;

  # Imports modules in a given root directory passing along callArgs to them
  importModules =
    {
      rootDir,
      callArgs ? { },
      exclude ? [ "default.nix" ],
    }:
    let
      nixModules = listNixModules { inherit rootDir exclude; };
    in
    lib.listToAttrs (
      map (name: {
        name = lib.removeSuffix ".nix" name;
        value = import "${rootDir}/${name}" callArgs;
      }) nixModules
    );

  # Applies pkgs.callPackage to all the modules in a root directory
  callPackages =
    {
      rootDir,
      pkgs,
      exclude ? [ "default.nix" ],
    }:
    let
      nixModules = listNixModules { inherit rootDir exclude; };
    in
    lib.listToAttrs (
      map (name: {
        name = lib.removeSuffix ".nix" name;
        value = pkgs.callPackage "${rootDir}/${name}" { };
      }) nixModules
    );
}
