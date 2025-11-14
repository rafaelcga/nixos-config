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

  addToAddress =
    address: num:
    let
      octets = lib.splitString "." address;
      networkParts = lib.take 3 octets;
      lastOctetStr = lib.last octets;
      isValidAddress = lib.length octets == 4;

      newLastOctet = (lib.toInt lastOctetStr) + num;
      isValidResult = newLastOctet >= 0 && newLastOctet < 256;

    in
    if !isValidAddress then
      throw "addToAddress: Invalid IP address format: `${address}`"
    else if !isValidResult then
      throw "addToAddress: Octet overflow"
    else
      lib.concatStringsSep "." (networkParts ++ [ (builtins.toString newLastOctet) ]);
}
