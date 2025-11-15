{
  inputs,
  config,
  lib,
  specialArgs,
  hostName,
  userName,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  _module.args.hmConfig = config.home-manager.users.${userName};

  home-manager = {
    users.${userName} =
      let
        userConfigPath = "${inputs.self}/homes/${userName}@${hostName}";
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
