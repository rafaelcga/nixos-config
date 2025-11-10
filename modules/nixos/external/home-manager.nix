{
  inputs,
  config,
  lib,
  specialArgs,
  ...
}:
let
  inherit (config.modules.nixos) user;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  _module.args.hmConfig = config.home-manager.users.${user.name};

  home-manager = {
    users.${user.name} =
      let
        userConfigPath = "${inputs.self}/homes/${user.name}@${config.networking.hostName}";
      in
      {
        imports = [
          "${inputs.self}/modules/home-manager"
        ]
        ++ lib.optionals (lib.pathExists userConfigPath) [ userConfigPath ];
        home.stateVersion = config.system.stateVersion;
      };

    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";

    extraSpecialArgs = specialArgs;
  };
}
