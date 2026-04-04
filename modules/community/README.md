# Community Modules

This directory exposes the reusable, Dendrix-style surface of the flake.

The goal is to keep broadly reusable modules under a stable public namespace while
leaving host wiring, secrets, and user-specific assembly in their existing private
locations.

## Exported Trees

- `homeManager`: reusable Home Manager programs, languages, and composed aspects
- `nixos`: reusable NixOS profiles, shared services, and composed aspects
- `darwin`: reusable Darwin shared modules and composed aspects

These trees are exposed under the flake's `moduleTrees` output.
Flat aliases are also exported through the standard `homeManagerModules`,
`nixosModules`, and `darwinModules` outputs for easier consumption by
ordinary flakes.

Anything secret-oriented, inventory-specific, or dependent on private/internal git
sources belongs in the internal private tree instead of this exported surface.

## Current Boundary

Reusable:

- `configs/programs/*`
- `configs/dev/languages/*`
- `configs/profiles/system/*`
- `configs/server.nix`
- `configs/nix-caches.nix`

Private for now:

- `hosts/*`
- `secrets/*`
- `configs/network.nix`
- `configs/users/ij.nix`
- `configs/users/mj.nix`

## Example

```nix
{
  inputs.dotfiles.url = "github:ijohanne/dotfiles-ng";

  outputs = { self, nixpkgs, dotfiles, ... }: {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        dotfiles.nixosModules.serverBase
      ];
    };
  };
}
```

