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

  generateAgeKeyScript = pkgs.writeShellScript "generate_age_key.sh" ''
    set -e
    mkdir -p "${sopsAgeKeysDir}"
    ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "${privateKeyPath}" > "${sopsAgeKeyFile}"
    chown -R ${userName}:${userGroup} "${sopsAgeKeysDir}"
  '';
in
{
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
    serviceConfig = {
      Type = "oneshot";
      ExecStart = generateAgeKeyScript;
    };
    wantedBy = [ "multi-user.target" ];
  };
}
