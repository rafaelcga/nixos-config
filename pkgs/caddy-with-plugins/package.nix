{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.15.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.15.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.15.1"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-JxiiX3sVkHfUnb7CXsRuCM5f0dT1t5qpddtNK/b+VSk=";
  doInstallCheck = false;
}
