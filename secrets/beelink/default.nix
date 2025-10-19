{ config, ... }:
{
  sops.secrets = {
    porkbun_api_key = { };
    porkbun_api_secret_key = { };
    crowdsec_api_key = { };
    domain_name = { };
  };

  sops.templates = {
    "caddy-env".content = ''
      PORKBUN_API_KEY=${config.sops.placeholder.porkbun_api_key}
      PORKBUN_API_SECRET_KEY=${config.sops.placeholder.porkbun_api_secret_key}
      CROWDSEC_API_KEY=${config.sops.placeholder.crowdsec_api_key}
    '';
    "caddy-bouncer-env".content = ''
      BOUNCER_NAME=caddy
      BOUNCER_KEY=${config.sops.placeholder.crowdsec_api_key}
    '';
  };
}
