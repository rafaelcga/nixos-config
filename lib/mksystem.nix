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
          "${inputs.self}/hosts/${hostName}/config.nix"
          "${inputs.self}/overlays"
          {
            system = { inherit stateVersion; };
            home-manager = {
              backupFileExtension = "bak";
              extraSpecialArgs = specialArgs;
              users.${userName} = {
                imports = [
                  "${inputs.self}/hosts/${hostName}/config-home.nix"
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
