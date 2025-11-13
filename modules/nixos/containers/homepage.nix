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

  instances = {
    servarr = {
      mkSecretName = service: "servarr/${service}";
      fields = [
        "wanted"
        "queued"
        "missing"
      ];
    };
  };

  apiKeyName = service: "HOMEPAGE_VAR_${lib.toUpper service}_API_KEY";

  mkServiceGroup =
    instance: config:
    let
      inherit (cfg_instances.${instance}) enable localAddress containerPorts;
      mkSettings =
        service: _:
        let
          port = containerPorts.${service};
          href = "${localAddress}:${port}";
        in
        {
          "${utils.capitalizeFirst service}" = {
            icon = "${service}.png";
            inherit href;
            widget = {
              type = service;
              url = href;
              key = "{{${apiKeyName service}}";
              inherit (config) fields;
            };
          };
        };
    in
    lib.optionals enable [
      { "${utils.capitalizeFirst instance}" = lib.mapAttrsToList mkSettings containerPorts; }
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
          # Maps a container and a lambda to obtain a service's SOPS secret name
          mkSecrets =
            instance: config:
            let
              mkSecret = service: _: lib.nameValuePair (config.mkSecretName service) { };
            in
            lib.mkIf cfg_instances.${instance}.enable (
              lib.mapAttrs' mkSecret cfg_instances.${instance}.containerPorts
            );
        in
        lib.mkMerge (lib.mapAttrsToList mkSecrets instances);

      templates."homepage-env".content =
        let
          mkEnvFile =
            instance: config:
            let
              mkApiKey =
                service:
                let
                  apiKey = config.sops.placeholder."${config.mkSecretName service}";
                in
                "${apiKeyName service}=${apiKey}";

              envVars =
                let
                  services = lib.attrNames cfg_instances.${instance}.containerPorts;
                in
                lib.concatMapStringsSep "\n" mkApiKey services;
            in
            lib.optionalString cfg_instances.${instance}.enable envVars;
        in
        lib.concatMapStringsSep "\n" (lib.mapAttrsToList mkEnvFile instances);
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
          services = lib.concat (lib.mapAttrsToList mkServiceGroup instances);
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
