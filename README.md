<div align="center">
<img alt="NixOS" src="resources/splash/nix-snowflake-rainbow-pastel.svg" width="140px"/>

# NixOS Config
My [NixOS](https://nixos.org/) configuration, using
[`home-manager`](https://github.com/nix-community/home-manager),
[`sops-nix`](https://github.com/Mic92/sops-nix) and
[`disko`](https://github.com/nix-community/disko).

</div>

> [!IMPORTANT]
> **Disclaimer:** This configuration is not intended to be cloned and built as-is,
> it uses secrets and declarative disk partition, so it **_will_** result in a broken
> install for you.
>
> However, feel free to use it as a reference, fork it and modify it to your hearts
> content.

## Install

There are two ways to easily bootstrap an install of a system: using `disko` +
`nixos-install` for local ISOs, and
[`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere) through SSH.

### Local ISO

0. Setup `hostname` variable to select which system to build.
```bash
export hostname="<hostname>"
```

1. Procure SSH key and copy it to `/tmp/ssh/id_ed25519` in the live ISO.
```bash
mkdir -p /tmp/ssh
cp <key_path> /tmp/ssh/id_ed25519
chmod 0600 /tmp/ssh/id_ed25519
```

2. Clone the repo, `cd` into it and update the `hardware-configuration.nix` to
be that of the target host (omitting disk configuration):
```bash
git clone https://github.com/rafaelcga/nixos-config.git
cd nixos-config
nixos-generate-config --show-hardware-config --no-filesystems > hosts/$hostname/hardware-configuration.nix
git add . # In case there was no prior configuration
```

3. Partition the disks with `disko`:
```bash
sudo nix --experimental-features "nix-command flakes" \
    run github:nix-community/disko/latest -- \
    --mode destroy,format,mount ./hosts/$hostname/config-disk.nix
```

4. Perform install with `nixos-install`:
```bash
sudo nixos-install --flake ".#$hostname"
```

### SSH

_TODO_

## Maintenance

Use [`nh`](https://github.com/nix-community/nh) as a `nix` helper once the system is deployed.
