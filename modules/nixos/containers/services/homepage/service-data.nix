{
  lidarr = {
    displayName = "Lidarr";
    description = "Music collection manager";
    container = "servarr";
    apiAuth = "key";
    widgetFields = [
      "wanted"
      "queued"
      "artists"
    ];
    extraConfig = { };
  };

  radarr = {
    displayName = "Radarr";
    description = "Movie collection manager";
    container = "servarr";
    apiAuth = "key";
    widgetFields = [
      "wanted"
      "queued"
      "movies"
    ];
    extraConfig = { };
  };

  sonarr = {
    displayName = "Sonarr";
    description = "TV series collection manager";
    container = "servarr";
    apiAuth = "key";
    widgetFields = [
      "wanted"
      "queued"
      "series"
    ];
    extraConfig = { };
  };

  prowlarr = {
    displayName = "Prowlarr";
    description = "Indexer manager and proxy";
    container = "servarr";
    apiAuth = "key";
    widgetFields = [
      "numberOfGrabs"
      "numberOfQueries"
      "numberOfFailGrabs"
      "numberOfFailQueries"
    ];
    extraConfig = { };
  };

  qbittorrent = {
    displayName = "qBittorrent";
    description = "BitTorrent client";
    container = "qbittorrent";
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
    displayName = "Jellyfin";
    description = "Media streaming server";
    container = "jellyfin";
    apiAuth = null;
    widgetFields = [ ];
    extraConfig = { };
  };

  ddns-updater = {
    displayName = "DNS Updater";
    description = "Dynamic DNS record updater";
    container = "ddns-updater";
    apiAuth = null;
    widgetFields = [ ];
    extraConfig = { };
  };
}
