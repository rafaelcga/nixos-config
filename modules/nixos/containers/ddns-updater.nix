{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances.ddns-updater or { enable = false; };

  secrets = {
    "web_domain" = { };
    "porkbun/api_key" = { };
    "porkbun/api_secret_key" = { };
  };
  # https://github.com/qdm12/ddns-updater/blob/master/docs/porkbun.md
  jsonConfig = ''
    {
      "settings": [
        {
          "provider": "porkbun",
          "domain": "*.${config.sops.placeholder."web_domain"}",
          "api_key": "${config.sops.placeholder."porkbun/api_key"}",
          "secret_api_key": "${config.sops.placeholder."porkbun/api_secret_key"}"
        }
      ]
    }
  '';
in
{
  config = lib.mkIf cfg.enable {
    sops = {
      inherit secrets;
      templates."ddns-updater/config.json".content = jsonConfig;
    };

    modules.nixos.containers.instances.ddns-updater.containerPort = 8000;

    containers.ddns-updater = {
      bindMounts = {
        "${config.sops.templates."ddns-updater/config.json".path}" = {
          isReadOnly = true;
        };
      };

      config = {
        services.ddns-updater = {
          enable = true;
          environment = {
            CONFIG_FILEPATH = config.sops.templates."ddns-updater/config.json".path;
            LISTENING_ADDRESS = ":${builtins.toString cfg.containerPort}";
            TZ = "Europe/Madrid";
          };
        };
      };
    };
  };
}
