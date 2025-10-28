{ caddy }:
let
  porkbunVersion = "v0.3.1";
  bouncerVersion = "v0.9.2";

  plugins = [
    "github.com/caddy-dns/porkbun@${porkbunVersion}"
    "github.com/hslatman/caddy-crowdsec-bouncer/http@${bouncerVersion}"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@${bouncerVersion}"
    "github.com/hslatman/caddy-crowdsec-bouncer/layer4@${bouncerVersion}"
  ];
in
caddy.withPlugins {
  inherit plugins;
  hash = "sha256-GVUr7jLdWbq9qySW79vkq5sccpDgBua2ndsPjcev9Fc=";
  doInstallCheck = false;
}
