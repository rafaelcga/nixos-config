{ lib, ... }:
let
  excludedFiles = [
    "default.nix"
    "extended-lib.nix"
  ];

  allFiles = builtins.attrNames (builtins.readDir ./.);
  nixFiles = builtins.filter (
    name: lib.hasSuffix ".nix" name && !(lib.elem name excludedFiles)
  ) allFiles;
  nixNames = builtins.map (name: lib.removeSuffix ".nix" name) nixFiles;

  modules = lib.genAttrs nixNames (name: import ./${name}.nix { inherit lib; });
  moduleFunctions = lib.mergeAttrsList (lib.attrValues modules);
in
moduleFunctions // modules # modules take precedence in merge
