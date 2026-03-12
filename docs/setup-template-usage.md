# Setup Template Generator

Generate new host and user configurations for the dotfiles flake.

## Quick start

```bash
# Interactive — prompts for user + host details
nix run .#setup-template -- new

# Non-interactive — from a config file
nix run .#setup-template -- generate --config setup.json

# Preview output without writing
nix run .#setup-template -- new --dry-run
nix run .#setup-template -- generate --config setup.json --dry-run
```

## CLI reference

```
setup-template new [--output <dir>] [--yes] [--dry-run] [--repo-ref <flake-ref>]
setup-template generate --config <file.json|file.toml> [--output <dir>] [--force] [--dry-run]
```

| Flag | Description |
|------|-------------|
| `--output <dir>` | Write files relative to this directory (default: `.`) |
| `--yes` | Accept defaults without prompting (new only) |
| `--dry-run` | Print planned files and flake snippet without writing |
| `--force` | Overwrite existing files (generate only) |
| `--repo-ref <ref>` | Override flake reference (default: `github:ijohanne/dotfiles-ng`) |
| `--config <path>` | Path to JSON or TOML config file (generate only) |

## What gets generated

| File | Purpose |
|------|---------|
| `configs/users.nix` | User registry — merge with the existing file if you already have users |
| `hosts/<name>/configuration.nix` | NixOS or Darwin system configuration with deploy script wiring |
| `hosts/<name>/home.nix` | Home-manager config importing user, program, and language modules |
| *(printed to stdout)* | Flake snippet to paste into `flake.nix` |

## Where to edit first

1. **`configs/users.nix`** — If you have existing users, merge the generated block into the existing file rather than replacing it.
2. **`hosts/<name>/configuration.nix`** — Add hardware-specific config, additional packages, services.
3. **`hosts/<name>/home.nix`** — Add or remove program/language module imports.
4. **`flake.nix`** — Paste the printed snippet into the outputs.

## Deploy script behavior

The generator wires deploy scripts based on host role and platform:

| Scenario | Helper | Command |
|----------|--------|---------|
| Linux desktop (local) | `mkLocalDeployScript` | `nixos-rebuild switch --flake` |
| Darwin desktop (local) | `mkLocalDeployScript` | `darwin-rebuild switch --flake` (no sudo) |
| Linux server (remote) | `mkDeployScript` | Checks for local checkout, falls back to GitHub |

Deploy scripts are added to `environment.systemPackages` and available as `deploy-<hostname>` after activation.

## Build and switch commands

### Darwin

```bash
# Test build
nix build .#darwinConfigurations.<name>.system

# Activate
darwin-rebuild switch --flake .#<name>
```

### NixOS (local)

```bash
# Test build
nix build .#nixosConfigurations.<name>.config.system.build.toplevel

# Activate
sudo nixos-rebuild switch --flake .#<name>
```

### NixOS (remote server)

```bash
# Push changes first, then deploy via SSH
git push
ssh <host> deploy-<name>
```

## Network follow-up

If the new host is on the local network, add it to `configs/network.nix`:

```nix
my-host = {
  ip = "10.255.101.XXX";
  mac = "aa:bb:cc:dd:ee:ff";  # omit for static-only
};
```

Then rebuild the router/DNS host to pick up DNS/DHCP changes.

See [NETWORK.md](../NETWORK.md) for VLAN assignments, DNAT rules, and the full host registry.

## Secrets follow-up

If you enabled secrets (`modules.secrets = true`):

1. Get the host's age public key:
   ```bash
   # From inside the dev shell
   ssh-to-age-remote root@<host-ip>
   ```

2. Add the key to `.sops.yaml`:
   ```yaml
   keys:
     - &newhost age1...public-key...

   creation_rules:
     - path_regex: secrets/newhost\.(yaml|json|env|ini)$
       key_groups:
         - age:
             - *ij
             - *newhost
   ```

3. Create the secrets file:
   ```bash
   sops secrets/<hostname>.yaml
   ```

## Troubleshooting

**"file already exists"** — Use `--force` to overwrite, or `--dry-run` to preview first.

**"primary_user not found in users list"** — Every host's `primary_user` must match a username in the `users` array.

**"unsupported config format"** — Config files must have `.json` or `.toml` extension.

**Build fails after pasting flake snippet** — Ensure the snippet is inside the correct `outputs` block and that `mkNixosHost`/`mkDarwinHost`/`mkHomeManagerModule`/`mkPkgsUnstable` are in scope (they're defined in the `let` block of this flake).

**Missing `configs/users/<name>.nix`** — The generated `home.nix` imports a per-user config file. If one doesn't exist yet, create it by copying `configs/users/ij.nix` as a starting point, or import `configs/users/common.nix` directly.
