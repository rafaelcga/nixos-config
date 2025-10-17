{ lib, ... }:
{
  imports = lib.local.listNixPaths { rootDir = ./.; };
}
