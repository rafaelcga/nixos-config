{
  inputs,
  config,
  lib,
  specialArgs,
  ...
}:
let
  inherit (config.modules.nixos) user;
  userHomeConfig = "${inputs.self}/homes/${user.name}@${config.networking.hostName}";
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    sharedModules = [ "${inputs.self}/modules/home-manager" ];
    users.${user.name} = {
      imports = lib.optionals (builtins.pathExists userHomeConfig) [ userHomeConfig ];
      home = { inherit (config.system) stateVersion; };
    };

    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";

    extraSpecialArgs = specialArgs;
  };
}
