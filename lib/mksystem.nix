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
      inherit (inputs)
        nixpkgs
        home-manager
        catppuccin
        sops-nix
        ;
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
      ${hostName} = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          catppuccin.nixosModules.catppuccin

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
              sharedModules = [
                sops-nix.homeManagerModules.sops
                catppuccin.homeModules.catppuccin

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
