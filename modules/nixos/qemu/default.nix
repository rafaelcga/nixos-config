{
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.qemu;
in
{
  options.modules.nixos.qemu = {
    enable = lib.mkEnableOption "QEMU and virt-manager configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.virt-manager.enable = true;
    users.groups.libvirtd.members = [ userName ];
    virtualisation = {
      libvirtd.enable = true;
      spiceUSBRedirection.enable = true;
    };
  };
}
