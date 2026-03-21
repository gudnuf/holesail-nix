# holesail-nix

Nix flake packaging [holesail](https://holesail.io) v2.4.1 with a NixOS module for running persistent P2P tunnels as systemd services. Holesail creates encrypted peer-to-peer tunnels using a shared key — no port forwarding, no central server, no static IP required. This flake packages the holesail CLI for all major platforms and provides a NixOS module to declaratively manage server, client, and filemanager tunnel instances.

## Quick start

```
nix run github:gudnuf/holesail-nix -- --live 8080
```

## Adding to a flake

```nix
inputs.holesail = {
  url = "github:gudnuf/holesail-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add `inputs.holesail.nixosModules.default` to your NixOS `modules` list.

## NixOS module examples

### Server — expose a local service

```nix
services.holesail.tunnels.ssh = {
  role = "server";
  port = 22;
  keyFile = "/run/secrets/holesail-ssh-key";
};
```

### Client — connect to a remote tunnel

```nix
services.holesail.tunnels.hetzner-ssh = {
  role = "client";
  keyFile = "/run/secrets/holesail-hetzner-key";
  port = 2222;
};
```

The `port` here is the local port the tunnel endpoint binds to. Omit it to auto-detect from the key.

### Filemanager — share a directory over the web

```nix
services.holesail.tunnels.shared-files = {
  role = "filemanager";
  directory = "/srv/shared";
  port = 5409;
  passwordFile = "/run/secrets/holesail-fm-password";
};
```

### Bidirectional — server and client on the same host

You can define any number of tunnels on one host. A machine can simultaneously expose its own services and connect to remote ones:

```nix
services.holesail.tunnels = {
  ssh-server = {
    role = "server";
    port = 22;
    keyFile = "/run/secrets/holesail-ssh-key";
  };
  hetzner-ssh = {
    role = "client";
    keyFile = "/run/secrets/holesail-hetzner-key";
    port = 2222;
  };
};
```

## Darwin usage

The NixOS module is Linux-only (systemd). On macOS, use the package directly:

```nix
environment.systemPackages = [
  inputs.holesail.packages.aarch64-darwin.default
];
```

Then run `holesail` from your terminal.

## holesail-status

On NixOS systems with the module active, `holesail-status` is automatically available. Running it with no arguments prints a summary table of all tunnel instances:

```
 Tunnel           Role           Status     Port    Key
 ──────────────────────────────────────────────────────────────
 ssh              server         active     22      hs://abc123...
 hetzner-ssh      client         active     2222    —
```

Pass a tunnel name for a detailed view including the full key and a journalctl hint:

```
holesail-status ssh
```

## Key management

**Auto-generated (default for server and filemanager):** If `keyFile` is not set, the module generates a random 32-byte hex key on first start and stores it at `/var/lib/holesail-<name>/key`. The key persists across restarts. Share this key out-of-band with whoever needs to connect.

**Bring your own (`keyFile`):** Point `keyFile` at a path containing the key (a hex string >= 32 chars or an `hs://` URL). This integrates with secret management tools like [sops-nix](https://github.com/Mic92/sops-nix) or [agenix](https://github.com/ryantm/agenix). The key file is read at runtime and never copied into the Nix store. `keyFile` is required for the `client` role.

For the full set of options, run `nixos-option services.holesail.tunnels`.

## Upstream

https://holesail.io
