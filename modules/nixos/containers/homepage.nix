{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg_instances = config.modules.nixos.containers.instances;
  cfg = cfg_instances.homepage;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  apiKeyName = service: "HOMEPAGE_VAR_${lib.toUpper service}_API_KEY";

  serviceData = {
    lidarr = {
      instance = "servarr";
      secret = "servarr/lidarr";
      widgetFields = [
        "wanted"
        "queued"
        "artists"
      ];
    };
  };

  services =
    let
      mkService =
        service: data:
        let
          instance = cfg_instances.${data.instance};
          port = builtins.toString instance.containerPorts.${service};
          href = "${instance.localAddress}:${port}";
        in
        {
          "${utils.capitalizeFirst service}" = lib.mkIf instance.enable {
            icon = "${service}.png";
            inherit href;
            widget = {
              type = service;
              url = href;
              key = "{{${apiKeyName service}}";
              fields = data.widgetFields;
            };
          };
        };

      mkGroup =
        serviceNames:
        let
          groupServices = lib.filterAttrs (name: _: lib.elem name serviceNames) serviceData;
        in
        lib.mapAttrsToList mkService groupServices;
    in
    [
      {
        "Media Management" = mkGroup [
          "lidarr"
          "radarr"
          "sonarr"
          "prowlarr"
          "qbittorrent"
        ];
      }
    ];
in
lib.mkMerge [
  {
    modules.nixos.containers.instances.homepage = {
      containerPort = 8082;
      containerDataDir = "/etc/homepage-dashboard";
    };
  }
  (lib.mkIf cfg.enable {
    sops = {
      secrets =
        let
          mkSecret =
            service: data:
            let
              instance = cfg_instances.${data.instance};
            in
            {
              "${data.secret}" = lib.mkIf instance.enable { };
            };
        in
        lib.mkMerge (lib.mapAttrsToList mkSecret serviceData);

      templates."homepage-env".content =
        let
          mkEnvVar =
            service: data:
            let
              instance = cfg_instances.${data.instance};
              apiKey = config.sops.placeholder."${data.secret}";
            in
            lib.optionalString instance.enable "${apiKeyName service}=${apiKey}";

          enabledEnvVars =
            let
              envVars = lib.mapAttrsToList mkEnvVar serviceData;
            in
            lib.filter (var: var != "") envVars;
        in
        lib.concatStringsSep "\n" enabledEnvVars;
    };

    containers.homepage = {
      bindMounts = {
        "${config.sops.templates."homepage-env".path}" = {
          isReadOnly = true;
        };
      };

      config = {
        services.homepage-dashboard = {
          enable = true;
          listenPort = cfg.containerPort;
          openFirewall = true;
          environmentFile = config.sops.templates."homepage-env".path;
          inherit services;
        };

        systemd.services.link-cache = {
          description = "Links cache to config directory";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              let
                cacheDir = "/var/cache/homepage-dashboard";
              in
              ''
                ln -snf "${cacheDir}" "${cfg.containerDataDir}/cache"
              '';
          };
        };
      };
    };
  })
]
