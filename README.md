# nixos-config

Apply this configuration:
```bash
sudo nixos-rebuild switch --flake github:rafaelcga/nixos-config#<hostname>
```

Regenerate `hardware-configuration.nix`:
```bash
nixos-generate-config --show-hardware-config > ./hosts/<hostname>/hardware-configuration.nix
```
