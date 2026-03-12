# setup-template

Scaffold new host and user configurations for the dotfiles flake.

## Quick start

```bash
# Interactive wizard
nix run .#setup-template -- new

# From config file
nix run .#setup-template -- generate --config setup.json

# Preview without writing
nix run .#setup-template -- generate --config setup.json --dry-run
```

## CLI

```
setup-template new [--output <dir>] [--yes] [--dry-run] [--repo-ref <flake-ref>]
setup-template generate --config <setup.json|setup.toml> [--output <dir>] [--force] [--dry-run]
```

### `new` — Interactive wizard

Prompts for one user and one host, then generates files.

- `--yes` — accept defaults without prompting
- `--dry-run` — print planned output without writing
- `--repo-ref` — override the flake reference (default: `github:ijohanne/dotfiles-ng`)

### `generate` — Config-driven

Reads a JSON or TOML config file and generates all files.

- `--force` — overwrite existing files
- `--dry-run` — preview output

## What gets generated

| File | Description |
|------|-------------|
| `configs/users.nix` | User registry (merge with existing) |
| `hosts/<name>/configuration.nix` | Host system config with deploy script |
| `hosts/<name>/home.nix` | Home-manager config with module imports |
| *(stdout)* | Flake snippet to paste into `flake.nix` |

## Renderer contract

The renderer produces files matching these flake conventions:

- **Deploy wiring**: `deploy = import ../../configs/deploy { inherit pkgs; };`
  - Desktop/local: `deploy.mkLocalDeployScript { name, host, rebuildCmd }`
  - Server/remote: `deploy.mkDeployScript { name, host }`
  - Darwin/local: `deploy.mkLocalDeployScript { name, host, rebuildCmd, useSudo = false }`
- **User registry**: same schema as `configs/users.nix` (`{ username, email, name, developer, shell, sshKeys }`)
- **Home-manager**: imports from `configs/users/<user>.nix`, `configs/programs/`, `configs/dev/languages/`
- **Flake snippet**: ready-to-paste `nixosConfigurations`/`darwinConfigurations` block using `mkNixosHost`/`mkDarwinHost` + `mkHomeManagerModule`

## Config file format

```json
{
  "version": 1,
  "repo_ref": "github:ijohanne/dotfiles-ng",
  "users": [{
    "username": "alice",
    "name": "Alice Smith",
    "email": "alice@example.com",
    "shell": "fish",
    "developer": true,
    "ssh_keys": ["ssh-ed25519 AAAA..."]
  }],
  "hosts": [{
    "name": "workstation",
    "platform": "linux",
    "arch": "x86_64",
    "role": "desktop",
    "nixpkgs": "unstable",
    "deploy_mode": "local",
    "primary_user": "alice",
    "additional_users": [],
    "modules": {
      "secrets": true,
      "neovim": true,
      "languages": ["nix", "rust"]
    }
  }]
}
```
