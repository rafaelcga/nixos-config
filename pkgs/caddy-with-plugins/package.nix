{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.15.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.15.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.15.0"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-CeumKPqNv1/fFVtYrb0ljXhqk1BNuEo1QQlatTxi0Zo=";
  doInstallCheck = false;
}
