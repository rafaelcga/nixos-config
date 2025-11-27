{
  lidarr = {
    displayName = "Lidarr";
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
}
