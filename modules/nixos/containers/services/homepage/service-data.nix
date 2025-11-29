{ inputs, lib }:
let
  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  mkServiceData =
    name: data:
    let
      defaultData = {
        displayName = utils.capitalizeFirst name;
        icon = "${name}.svg";
        description = "";
        type = name;
        container = name;
        apiAuth = null; # key or password
        widgetFields = [ ];
        extraConfig = { };
      };
    in
    defaultData // data;
in
lib.mapAttrs mkServiceData {
  lidarr = {
    description = "Music collection manager";
    container = "servarr";
    apiAuth = "key";
    widgetFields = [
      "wanted"
      "queued"
      "artists"
    ];
  };

  radarr = {
    description = "Movie collection manager";
    container = "servarr";
    apiAuth = "key";
    widgetFields = [
      "wanted"
      "queued"
      "movies"
    ];
  };

  sonarr = {
    description = "TV series collection manager";
    container = "servarr";
    apiAuth = "key";
    widgetFields = [
      "wanted"
      "queued"
      "series"
    ];
  };

  prowlarr = {
    description = "Indexer manager and proxy";
    container = "servarr";
    apiAuth = "key";
    widgetFields = [
      "numberOfGrabs"
      "numberOfQueries"
      "numberOfFailGrabs"
      "numberOfFailQueries"
    ];
  };

  qbittorrent = {
    displayName = "VueTorrent";
    icon = "vuetorrent";
    description = "BitTorrent client";
    apiAuth = "password";
    widgetFields = [
      "leech"
      "download"
      "seed"
      "upload"
    ];
    extraConfig = {
      enableLeechProgress = true;
      enableLeechSize = true;
    };
  };

  jellyfin = {
    description = "Media streaming server";
  };

  ddns-updater = {
    displayName = "DNS Updater";
    description = "Dynamic DNS record updater";
  };

  adguard = {
    displayName = "AdGuard Home";
    icon = "adguard-home";
    description = "Network-wide ad-blocking DNS server";
    apiAuth = "password";
    widgetFields = [
      "queries"
      "blocked"
      "filtered"
      "latency"
    ];
  };
}
