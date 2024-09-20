# Holesail Nix Flake

A Nix flake for building [holesail](https://holesail.io), a P2P based node package to expose your local ports on the Holepunch protocol.

## Use the Flake

To use this flake, make sure you have Nix installed and [flakes enabled](https://nixos.wiki/wiki/Flakes).

Note: The [Determinate Nix Installer](https://determinate.systems/) enables flakes by default. This is my preferred method of installing nix.

### Develop

To enter a dev shell with `holesail` and `holesail-manager` use:

```bash
nix develop github:gudnuf/holesail-nix/main
```
This will give you a dev shell with the package installed.

### Install

To install holesail use:

```bash
nix profile install github:gudnuf/holesail-nix/main
```

### In another flake

You can also add this flake as an input to your own flake:

```nix
inputs.holesail.url = "github:gudnuf/holesail-nix/main";
```

## Use Holesail

Refer to the [docs](https://docs.holesail.io/usage-guide/overview) for more, but you can get started with:

Create a holesail server:

```bash
holesail --live <port_to_make_live>
```

Copy the connection string, then connect to it on a different device:

```bash
holesail <connection_string>
```
