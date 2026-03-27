{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.10.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.10.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.10.1"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-oIgF9a2Ddri2nh90VOMWITjSnIbklUVAlaNMBJywtOo=";
  doInstallCheck = false;
}
