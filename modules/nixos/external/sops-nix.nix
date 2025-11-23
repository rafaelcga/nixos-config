{
  inputs,
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.sops-nix;
  user = config.users.users.${userName};
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.modules.nixos.sops-nix = {
    sshKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "${user.home}/.ssh/id_ed25519";
      description = "Path to the private SSH key";
    };

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
        cfg.sshKeyFile
        # System-wide location for private SSH key provisioning
        "/etc/ssh/sops_ed25519_key"
      ];
    };

    environment.systemPackages = with pkgs; [
      age
      sops
    ];

    # Generate age key file from private SSH
    systemd.services.generate-sops-age-key = {
      description = "Generates age key from private SSH for sops CLI";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = user.name;
        Group = user.group;
      };
      script =
        let
          ssh-to-age = lib.getExe pkgs.ssh-to-age;
        in
        ''
          set -euo pipefail

          mkdir -p "$(dirname "${cfg.ageKeyFile}")"
          ${ssh-to-age} -private-key -i "${cfg.sshKeyFile}" >"${cfg.ageKeyFile}"
        '';
    };
  };
}
