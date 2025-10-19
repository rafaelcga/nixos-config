{
  config,
  pkgs,
  inputs,
  hostName,
  userName,
  ...
}:
let
  homeDir = config.users.users.${userName}.home;
  userGroup = config.users.users.${userName}.group;

  privateKeyPath = "${homeDir}/.ssh/id_ed25519";
  sopsAgeKeysDir = "${homeDir}/.config/sops/age";
  sopsAgeKeyFile = "${sopsAgeKeysDir}/keys.txt";
in
{
  imports = [ "${inputs.self}/secrets/${hostName}" ];

  sops = {
    defaultSopsFile = "${inputs.self}/secrets/${hostName}/secrets.yaml";
    age.sshKeyPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
      privateKeyPath
      "/tmp/ssh/id_ed25519" # tmp location for local installs
    ];
    secrets = {
      user_password.neededForUsers = true;
    };
  };
  environment.systemPackages = with pkgs; [
    age
    sops
  ];

  # Generate age key file from private SSH
  systemd.services.generate-sops-age-key = {
    description = "Generate age key from private SSH for sops CLI";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = userName;
      Group = userGroup;
    };
    script = ''
      set -e
      mkdir -p "${sopsAgeKeysDir}"
      ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "${privateKeyPath}" > "${sopsAgeKeyFile}"
    '';
  };
}
