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

  updateLastOctet =
    address: newLastOctet:
    let
      octets = lib.splitString "." address;
      networkParts = lib.take 3 octets;

      isValidAddress = lib.length octets == 4;
      isValidResult = newLastOctet >= 0 && newLastOctet < 256;
    in
    if !isValidAddress then
      throw "updateLastOctet: Invalid IP address format: `${address}`"
    else if !isValidResult then
      throw "updateLastOctet: Octet overflow"
    else
      lib.concatStringsSep "." (networkParts ++ [ (builtins.toString newLastOctet) ]);

  addToLastOctet =
    address: num:
    let
      octets = lib.splitString "." address;
      networkParts = lib.take 3 octets;
      lastOctetStr = lib.last octets;
      newLastOctet = (lib.toInt lastOctetStr) + num;

      isValidAddress = lib.length octets == 4;
      isValidResult = newLastOctet >= 0 && newLastOctet < 256;

    in
    if !isValidAddress then
      throw "addToLastOctet: Invalid IP address format: `${address}`"
    else if !isValidResult then
      throw "addToLastOctet: Octet overflow"
    else
      lib.concatStringsSep "." (networkParts ++ [ (builtins.toString newLastOctet) ]);
}
