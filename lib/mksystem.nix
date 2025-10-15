{ lib, ... }:
{
  mkSystem =
    {
      inputs,
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
          inputs
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
          ../overlays
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
              sharedModules = homeManagerModules;
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
        ];
      };
    };
}
