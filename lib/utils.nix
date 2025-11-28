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

  addToLastOctet =
    address: num:
    let
      octets = lib.splitString "." address;

      restOctets = lib.take 3 octets;
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
      lib.concatStringsSep "." (restOctets ++ [ (builtins.toString newLastOctet) ]);

  addToLastHextet =
    address: num:
    let
      fullAddress = (lib.network.ipv6.fromString address).address;
      hextets = lib.splitString ":" fullAddress;
      numHextets = lib.length hextets;

      restHextets = lib.take (numHextets - 1) hextets;
      lastHextetStr = lib.last hextets;
      newLastHextet = (lib.fromHexString lastHextetStr) + num;

      isValidAddress = numHextets > 4;
      isValidResult = newLastHextet >= 0 && newLastHextet < 65535;
    in
    if !isValidAddress then
      throw "addToLastHextet: Invalid IP address format: `${address}`"
    else if !isValidResult then
      throw "addToLastHextet: Octet overflow"
    else
      lib.concatStringsSep ":" (restHextets ++ [ (lib.toHexString newLastHextet) ]);

  removeMask = block: lib.elemAt (lib.splitString "/" block) 0;
}
