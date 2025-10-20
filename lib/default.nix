{ lib, ... }@args:
let
  inherit (import ./utils.nix args) importModules;

  # Import functions and make them available at a higher scope
  libModules = importModules {
    rootDir = ./.;
    callArgs = args;
    exclude = [
      "default.nix"
      "extended-lib.nix"
    ];
  };
  libFunctions = lib.mergeAttrsList (lib.attrValues libModules);
in
libFunctions // libModules # modules take precedence in merge
