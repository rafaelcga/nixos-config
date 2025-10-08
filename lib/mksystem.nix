{ lib, ... }:
{
  mkSystem =
    {
      hostName,
      userName,
      stateVersion,
      nixosModules ? [ ],
      homeManagerModules ? [ ],
    }:
    let
      specialArgs = {
        inherit
          lib
          hostName
          userName
          ;
      };
    in
    {
      ${hostName} = lib.nixosSystem {
        inherit specialArgs;
        modules = nixosModules ++ [
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
              sharedModules = homeManagerModules ++ [
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
