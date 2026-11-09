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
  hash = "sha256-1nAvYp2gNl2GP/sOyYwEyzp8mQQY0Q3ElGEupaHRMv0=";
  doInstallCheck = false;
}
