{ lib, ... }:
{
  imports = lib.local.listNixPaths { };
}
