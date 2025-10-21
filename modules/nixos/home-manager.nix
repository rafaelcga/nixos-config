{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (config.modules.nixos) user;
  userHomeConfig = "${inputs.self}/home/${user.name}";
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    users.${user.name} = {
      imports = [
        "${inputs.self}/home/base.nix"
      ]
      ++ lib.optionals (builtins.pathExists userHomeConfig) [ userHomeConfig ];
      home = { inherit (config.system) stateVersion; };
    };

    backupFileExtension = "bak";

    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = { inherit inputs; };
  };
}
