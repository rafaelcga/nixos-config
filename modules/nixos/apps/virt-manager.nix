{
  config,
  lib,
  ...
}:
let
  inherit (config.modules.nixos) user;
  cfg = config.modules.nixos.virt-manager;
in
{
  options.modules.nixos.virt-manager = {
    enable = lib.mkEnableOption "Enable virt-manager";
  };

  config = lib.mkIf cfg.enable {
    programs.virt-manager.enable = true;

    virtualisation = {
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };
    users.groups.libvirtd.members = [ user.name ];
    networking.firewall.trustedInterfaces = [ "virbr0" ]; # Enables VM networking

    # Automatically add virtualization connection
    home-manager.users.${user.name} = {
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    };
  };
}
