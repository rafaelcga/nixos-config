{
  config,
  inputs,
  hostName,
  userName,
  ...
}:
let
  homeDir = config.users.users.${userName}.home;
in
{
  sops = {
    defaultSopsFile = "${inputs.self}/hosts/${hostName}/secrets.yaml";
    age.sshKeyPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
      "${homeDir}/.ssh/id_ed25519"
      "/tmp/ssh/id_ed25519" # tmp location for local installs
    ];
    secrets = {
      user_password.neededForUsers = true;
    };
  };
}
