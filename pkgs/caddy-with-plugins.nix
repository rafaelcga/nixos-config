{ caddy }:
let
  plugins = [
    "github.com/caddy-dns/porkbun@v0.3.1"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.9.2"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.9.2"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@v0.9.2"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-GVUr7jLdWbq9qySW79vkq5sccpDgBua2ndsPjcev9Fc=";
  doInstallCheck = false;
}
