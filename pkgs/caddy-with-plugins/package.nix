{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.9.2"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.9.2"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.9.2"
    "github.com/mholt/caddy-l4@v0.0.0-20260116154418-93f52b6a03ba"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-dM3P30F0iOJvD0IlqYx6i2t805FaZ3WAHwdY92bD32k=";
  doInstallCheck = false;
}
