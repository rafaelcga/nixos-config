<div align="center">
<img alt="NixOS" src="resources/splash/nix-snowflake-rainbow-pastel.svg" width="140px"/>

# NixOS Config
My [NixOS](https://nixos.org/) configuration, using
[`home-manager`](https://github.com/nix-community/home-manager),
[`sops-nix`](https://github.com/Mic92/sops-nix) and
[`disko`](https://github.com/nix-community/disko).

</div>

> [!IMPORTANT]
> **Disclaimer:** This configuration is not intended to be cloned and used as-is,
> it uses secrets and declarative disk partition, so it **_will_** result in a broken
> install for you.
>
> However, feel free to use it as a reference, fork it and modify it to your hearts
> content.

## Install

There are two ways to easily bootstrap an install of a system:
[`disko-install`](https://github.com/nix-community/disko/blob/master/docs/disko-install.md)
for local ISOs, and [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere)
through SSH.

### Local ISO

TODO

### SSH

TODO

## Maintenance

Use [`nh`](https://github.com/nix-community/nh) as a `nix` helper once the system is deployed.
