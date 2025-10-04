{ config, lib, ... }:
{
  boot.loader.limine.extraEntries = lib.mkIf config.boot.loader.limine.enable ''
    /Windows
        protocol: efi
        path: uuid(23f2eb9d-b5be-49bb-83f9-b486a3bcc7a3):/EFI/Microsoft/Boot/bootmgfw.efi
  '';
}
