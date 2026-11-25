{
  inputs,
  config,
  lib,
  pkgs,
  hostName,
  ...
}:
let
  cfg = config.modules.nixos.sops-nix;

  # Secrets are split per host: each host only holds the keys to decrypt
  # `secrets/<host>.yaml` and `secrets/common.yaml` (see `.sops.yaml`, generated
  # by `scripts/update_sops.sh`)
  secretsDir = "${inputs.self}/secrets";
  hostSecretsName = "${hostName}.yaml";
  hostSecretsPath = "${secretsDir}/${hostSecretsName}";
  hostKeyPubPath = "${inputs.self}/hosts/${hostName}/ssh_host_ed25519_key.pub";

  # `builtins.path` stores just this file: a bare "${inputs.self}/..." string
  # would tie the system's hash to every file in the repo
  storeSecretsFile =
    name:
    builtins.path {
      inherit name;
      path = "${secretsDir}/${name}";
    };
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.modules.nixos.sops-nix = {
    hostKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/ssh/ssh_host_ed25519_key";
      readOnly = true;
      description = ''
        SSH host key used as this host's age identity. Its public half must be
        enrolled in `hosts/<host>/ssh_host_ed25519_key.pub`
      '';
    };

    commonSopsFile = lib.mkOption {
      type = lib.types.path;
      default = storeSecretsFile "common.yaml";
      readOnly = true;
      description = ''
        Secrets file readable by every host. Set it as `sopsFile` of secrets
        shared by all hosts; the rest come from `secrets/<host>.yaml`
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.pathExists hostKeyPubPath && lib.pathExists hostSecretsPath;
        message = ''
          Host '${hostName}' is not enrolled for sops: expected
          hosts/${hostName}/ssh_host_ed25519_key.pub and secrets/${hostName}.yaml.
          Run `scripts/enroll_host.sh -n ${hostName} ...`.
        '';
      }
    ];

    sops = {
      defaultSopsFile = storeSecretsFile hostSecretsName;
      # Only the host key: never a personal key on the machine
      age.sshKeyPaths = [ cfg.hostKeyFile ];
      gnupg.sshKeyPaths = [ ];
    };

    # For editing secrets: sops reads ~/.ssh/id_ed25519 directly
    environment.systemPackages = with pkgs; [
      age
      sops
      ssh-to-age
    ];
  };
}
