{ inputs, ... }:
{
  imports = [
    "${inputs.self}/modules/nixos"
  ];

  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
}
