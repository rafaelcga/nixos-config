{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.10.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.10.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.10.0"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-wdq4UBAF8R9Ju3P2xszAA5jqRrWVQdtqo70wu0QIsLc=";
  doInstallCheck = false;
}
