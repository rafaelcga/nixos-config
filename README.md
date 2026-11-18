<div align="center">
<img alt="NixOS" src="resources/splash/nix-snowflake-rainbow-pastel.svg" width="140px"/>

# NixOS Config

My [NixOS](https://nixos.org/) configuration, using
[`flake-parts`](https://github.com/hercules-ci/flake-parts),
[`home-manager`](https://github.com/nix-community/home-manager),
[`sops-nix`](https://github.com/Mic92/sops-nix) and
[`disko`](https://github.com/nix-community/disko).

</div>

> [!IMPORTANT]
> This configuration is not meant to be cloned and built as-is: it depends on my
> secrets and declarative disk partitioning, so it **_will_** break your install.
> Feel free to use it as a reference, or fork it and adapt it to your heart's content.

## Install

Each host lives in `hosts/<hostname>`. Both install scripts partition the disks with
`disko` and copy an SSH private key to `/etc/ssh/sops_ed25519_key`, so `sops-nix`
can decrypt secrets on first boot.

### Local (from a NixOS ISO)

```sh
./scripts/local_install.sh -n <hostname> -k <ssh_key_path>
```

This also generates `hardware-configuration.nix` for the machine before installing.

### Remote (over SSH, with [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere))

```sh
./scripts/remote_install.sh -n <hostname> -k <ssh_key_path> <user@host>
./scripts/remote_install.sh -n <hostname> -t  # dry run in a VM
```

### After the first boot

Regenerate the hardware configuration on the new system, then commit and push it:

```sh
./scripts/generate_hardware.sh  # defaults to the current hostname
```

## Maintenance

Once the system is deployed, use [`nh`](https://github.com/nix-community/nh) to
rebuild and update it.
