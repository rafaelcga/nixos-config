{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) user;
  cfg = config.modules.nixos.sops-nix;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.modules.nixos.sops-nix = {
    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "${user.home}/.config/sops/age/keys.txt";
      description = "Path to age key file to be generated from private SSH key";
    };
  };

  config = {
    sops = {
      defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
      age.sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        user.sshPrivateKey
        "/tmp/ssh/id_ed25519" # tmp location for local installs
      ];
    };

    environment.systemPackages = with pkgs; [
      age
      sops
    ];

    sops.secrets."passwords/services" = { };
    sops.templates."ssh-env".content = ''
      SSH_PASSPHRASE=${config.sops.placeholder."passwords/services"}
    '';

    # Generate age key file from private SSH
    systemd.services.generate-sops-age-key = {
      description = "Generates age key from private SSH for sops CLI";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = user.name;
        Group = user.group;
        EnvironmentFile = config.sops.templates."ssh-env".path;
      };
      script = ''
        set -euo pipefail

        # Make temporary key with no passphrase
        TMP_KEY=$(mktemp)
        chmod 600 "$TMP_KEY"
        cp "${user.sshPrivateKey}" "$TMP_KEY"
        ssh-keygen -p -P "$SSH_PASSPHRASE" -N "" -f "$TMP_KEY"

        mkdir -p "$(dirname "${cfg.ageKeyFile}")"
        ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$TMP_KEY" > "${cfg.ageKeyFile}"
      '';
    };
  };
}
