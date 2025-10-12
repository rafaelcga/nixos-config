# nixos-config

Fresh install locally with [`disko`](https://github.com/nix-community/disko):
```bash
nixos-generate-config --show-hardware-config --no-filesystems > ./hosts/<hostname>/hardware-configuration.nix
git add .
sudo nix --experimental-features "nix-command flakes" run \
    "github:nix-community/disko/latest#disko-install" -- \
    --write-efi-boot-entries --flake ".#<hostname>" --disk main "<device>"
```

Use [`nh`](https://github.com/nix-community/nh) once the system is deployed.
