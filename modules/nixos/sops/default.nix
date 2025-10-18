{
  config,
  inputs,
  hostName,
  userName,
  ...
}:
let
  privateKeyPath = "${config.users.users.${userName}.home}/.ssh/id_ed25519";
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
  environment.sessionVariables = {
    SOPS_AGE_SSH_PRIVATE_KEY_FILE = privateKeyPath; # ensure sops CLI works
  };
}
