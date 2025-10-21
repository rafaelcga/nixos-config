{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (config.modules.nixos.user) name;
  userConfigPath = "${inputs.self}/home/${name}";
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    users.${name} = {
      imports = [
        "${inputs.self}/home/base.nix"
      ]
      ++ lib.optionals (builtins.pathExists userConfigPath) [ userConfigPath ];
      home = { inherit (config.system) stateVersion; };
    };

    useGlobalPkgs = true;
    useUserPackages = true;

    backupFileExtension = "bak";
    extraSpecialArgs = { inherit inputs lib; };
  };
}
