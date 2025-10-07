{ lib, ... }:
{
  mkSystem =
    {
      inputs,
      hostName,
      userName,
      stateVersion,
    }:
    let
      externalNixosModules = with inputs; [
        home-manager.nixosModules.home-manager
        sops-nix.nixosModules.sops
        catppuccin.nixosModules.catppuccin
      ];
      externalHomeManagerModules = with inputs; [
        sops-nix.homeManagerModules.sops
        catppuccin.homeModules.catppuccin
      ];
      specialArgs = {
        inherit
          lib
          inputs
          hostName
          userName
          ;
      };
    in
    {
      ${hostName} = inputs.nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = externalNixosModules ++ [
          ../hosts/${hostName}/config.nix
          ../secrets
          {
            system = { inherit stateVersion; };
            home-manager = {
              backupFileExtension = "bak";
              extraSpecialArgs = specialArgs;
              users.${userName} = {
                imports = [
                  ../hosts/${hostName}/config-home.nix
                ];
                home = { inherit stateVersion; };
              };
              sharedModules = externalHomeManagerModules ++ [
                ../secrets
              ];
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
        ];
      };
    };
}
