{ inputs, config, ... }:
let
  inherit (config.modules.nixos) user;
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    users.${user.name} = {
      imports = [
        "${inputs.self}/home/base.nix"
      ];
      home = { inherit (config.system) stateVersion; };
    };

    backupFileExtension = "bak";

    useGlobalPkgs = true;
    useUserPackages = true;

    extraSpecialArgs = { inherit inputs; };
  };
}
