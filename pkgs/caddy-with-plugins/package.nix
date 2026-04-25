{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.12.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.12.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.12.1"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-bSCl/tb8JlMHezplHguLZ9MkCCArJNx7s6iBwRnXLCg=";
  doInstallCheck = false;
}
