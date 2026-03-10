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
  hash = "sha256-R3TPFmKRSy79/MJEU0cRFopDlvTn8kH2r9g0SC089hM=";
  doInstallCheck = false;
}
