{
  config,
  hostName,
  userName,
  ...
}:
let
  homeDir = config.users.users.${userName}.home or config.home.homeDirectory;
in
{
  sops = {
    defaultSopsFile = ../../../hosts/${hostName}/secrets.yaml;
    age.sshKeyPaths = [
      /etc/ssh/ssh_host_ed25519_key
      "${homeDir}/.ssh/id_ed25519"
    ];
  };
}
