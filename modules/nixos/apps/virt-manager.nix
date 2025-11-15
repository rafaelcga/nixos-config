{
  config,
  lib,
  userName,
  ...
}:
let
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
    users.groups.libvirtd.members = [ userName ];
    networking.firewall.trustedInterfaces = [ "virbr0" ]; # Enables VM networking

    # Automatically add virtualization connection
    home-manager.users.${userName} = {
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    };
  };
}
