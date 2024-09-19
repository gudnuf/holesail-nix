# Holesail Nix Flake

This repository contains a Nix flake for building [holesail](https://holesail.io), a P2P based node package to expose your local ports on the Holepunch protocol.

## Usage

To use this flake, make sure you have Nix installed and [flakes enabled](https://nixos.wiki/wiki/Flakes).

Note: The [Determinate Nix Installer](https://determinate.systems/) enables flakes by default. This is my preferred method of installing nix.

Then, you can run:

```bash
nix build github:gudnuf/holesail-nix/main
```

This will build the `holesail` package using the flake.

You can also add this flake as an input to your own flake:

```nix
inputs.holesail.url = "github:gudnuf/holesail-nix/main";
```
