{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.14.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.14.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.14.1"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-Tnjp/WRKnfyzo+sj0gq+mfeBtdTKA4l3EtJDf6MPjxo=";
  doInstallCheck = false;
}
