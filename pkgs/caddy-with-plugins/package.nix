{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.12.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.12.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.12.0"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-g7riPzZ29tRtVbg47ieJxIAClR6J6wbK+LAZbNsqOxg=";
  doInstallCheck = false;
}
