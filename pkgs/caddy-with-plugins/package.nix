{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.13.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.13.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.13.1"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-gpwB+bY1baQrD9LeIKFy0D6KM1ND1NjjpvMHTqx99j0=";
  doInstallCheck = false;
}
