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
`disko` and install the host's SSH host key, which is its only `sops-nix` identity.

### Secrets

Each host can only decrypt `secrets/common.yaml` and its own `secrets/<hostname>.yaml`,
using its SSH host key (enrolled in `hosts/<hostname>/ssh_host_ed25519_key.pub`). The
admins in `secrets/admins.txt` can decrypt everything with `sops`, straight from
`~/.ssh/id_ed25519`. `.sops.yaml` is generated: don't edit it by hand.

```sh
./scripts/enroll_host.sh -n <hostname> -s <ssh destination>  # enroll a running host
./scripts/enroll_host.sh -n <hostname> -g <dir>              # generate a key for a new install
./scripts/update_sops.sh  # after editing secrets/admins.txt
```

### Local (from a NixOS ISO)

On a machine that can edit the secrets, generate and enroll the host key, then commit
and push:

```sh
./scripts/enroll_host.sh -n <hostname> -g /path/to/usb
```

Then, on the target:

```sh
./scripts/local_install.sh -n <hostname> -k /path/to/usb/ssh_host_ed25519_key
```

This also generates `hardware-configuration.nix` for the machine before installing.
Delete the key from the USB drive afterwards.

### Remote (over SSH, with [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere))

```sh
./scripts/remote_install.sh -n <hostname> <user@host>  # generates and enrolls a host key
./scripts/remote_install.sh -n <hostname> -k <host_key> <user@host>  # reuses one
./scripts/remote_install.sh -n <hostname> -t  # dry run in a VM
```

Commit and push the enrollment afterwards.

### After the first boot

Regenerate the hardware configuration on the new system, then commit and push it:

```sh
./scripts/generate_hardware.sh  # defaults to the current hostname
```

## Maintenance

Once the system is deployed, use [`nh`](https://github.com/nix-community/nh) to
rebuild and update it.
