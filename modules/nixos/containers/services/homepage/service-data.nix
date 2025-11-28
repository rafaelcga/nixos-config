{ inputs, lib }:
let
  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  serviceOpts =
    { name, ... }:
    {
      displayName = lib.mkOption {
        type = lib.types.str;
        default = utils.capitalizeFirst name;
        description = "Name to display for the service";
      };

      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Service description";
      };

      icon = lib.mkOption {
        type = lib.types.str;
        default = name;
        apply = name: "${name}.svg";
        description = "Service icon";
      };

      type = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Homepage Dashboard service type";
      };

      container = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Container that holds the service";
      };

      apiAuth = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "key"
            "password"
          ]
        );
        default = null;
        description = "Service API authentication method (key or password)";
      };

      widgetFields = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Fields to be displayed in the service widget";
      };

      extraConfig = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Extra attributes to configure the service entry";
      };
    };
in
{
  options = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule serviceOpts);
    default = { };
  };

  config = {
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
      description = "BitTorrent client";
      icon = "vuetorrent";
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
      description = "Network-wide ad-blocking DNS server";
      icon = "adguard-home";
      apiAuth = "password";
      widgetFields = [
        "queries"
        "blocked"
        "filtered"
        "latency"
      ];
    };
  };
}
