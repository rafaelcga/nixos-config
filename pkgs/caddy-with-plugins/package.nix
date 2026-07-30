{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.14.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.14.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.14.0"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-xNZzJ2MisCBbaZCgE/z7FXQnv0uItsj/wPZSn+zSJMY=";
  doInstallCheck = false;
}
