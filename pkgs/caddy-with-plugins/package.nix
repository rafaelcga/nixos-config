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
  hash = "sha256-HXvZHmzG5n8Gnx7Du1bagzrI9bE2tbM6Hl6+cpGfw/k=";
  doInstallCheck = false;
}
