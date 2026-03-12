# Plan: setup-template generator (execution checklist)

## Outcome

Ship a Rust CLI exposed as:

```bash
nix run github:ijohanne/dotfiles-ng#setup-template
```

The generator must scaffold configs matching the current flake architecture and include onboarding docs for non-expert Nix users.

Rust is intentional here: maintainability, typed schema evolution, and better long-term debugging for this repo.

## Hard constraints (current repo)

- Use `configs/users.nix` as the user registry source.
- Respect `flake.nix` host helpers: `mkNixosHost`, `mkDarwinHost`, `mkHomeManagerModule`, `mkPkgsUnstable`.
- Respect Home Manager `_module.args.user` and `extraSpecialArgs` (`pkgs-unstable` pattern).
- Generate deploy scripts through `configs/deploy/default.nix`:
  - local hosts: `mkLocalDeployScript`
  - remote/server hosts: `mkDeployScript`
- Keep Rust pinned through flake (`rust-overlay` + `flake.lock`) for package builds and dev shell.
- Keep repo ref configurable (`github:ijohanne/dotfiles-ng` default, override via CLI/config).

Note: local checkout directory name may be `dotfiles`, but default remote flake ref remains `github:ijohanne/dotfiles-ng` unless overridden.

## CLI surface

- `setup-template new [--output <dir>] [--yes] [--dry-run] [--repo-ref <flake-ref>]`
- `setup-template generate --config <setup.json|setup.toml> [--output <dir>] [--force] [--dry-run]`

Wizard questions (minimum):
- first host: name, platform (`linux`/`darwin`), role (`desktop`/`server`), deploy mode
- first user: username, name, email, shell, `developer`, optional SSH keys
- initial module selections

## Implementation checklist

### 0) Spike and pattern capture

- Read and codify current patterns from:
  - `flake.nix`
  - `configs/deploy/default.nix`
  - `configs/users.nix`
  - one desktop host and one server host under `hosts/*/configuration.nix`
- Explicitly confirm how hosts currently consume deploy helpers (`import ../../configs/deploy { inherit pkgs; }` + `environment.systemPackages` entry) and record that as the canonical generation pattern.
- Produce a short renderer contract artifact in `tools/setup-template/README.md` or `src/render.rs` module docs.

Validation:
- renderer contract checked in before codegen logic

### 1) Scaffold crate + test harness

- Create `tools/setup-template/` with `Cargo.toml`, `Cargo.lock`, `src/`, `templates/`, `tests/fixtures/`.
- Add command skeleton and `--help`.
- Set Rust edition and MSRV policy in `Cargo.toml`/README.

Validation:
- `cargo build`
- fixture harness compiles

### 2) Schema + CLI

- Add versioned schema (`version`, users, hosts, modules, deploy mode, repo ref).
- Implement `new` and `generate` parsing.
- Add JSON/TOML load/save.
- Add strict schema validation with actionable field-level errors.

Validation:
- unit tests for parse/default/validation behavior

### 3) Wizard

- Implement interactive prompts and defaults.
- Normalize to schema used by renderer.
- Implement `--yes` behavior.

Validation:
- wizard run emits valid config model

### 4) Renderer

Dependency: finalize Step 5 flake integration strategy before freezing renderer templates.

- Deterministic rendering pipeline for both command paths.
- Render files compatible with current flake conventions:
  - `configs/users.nix`-style data
  - host definitions compatible with flake helper patterns
  - HM user wiring compatible with `_module.args.user`
- Add non-empty-dir checks and `--force`.
- `--dry-run` must print planned file tree and content diff preview.

Validation:
- golden tests for generated output in `tests/fixtures/`
- repeated generation is stable

### 5) Flake.nix integration strategy

- Choose one explicit strategy and implement it:
  1) auto-patch `flake.nix` idempotently, or
  2) emit a validated snippet + exact insertion instructions.
- Start with option (2) unless robust patching is implemented.
- Snippet output (option 2) must be ready-to-paste and complete, including:
  - `nixosConfigurations.<host> = mkNixosHost { ... };` or `darwinConfigurations.<host> = mkDarwinHost { ... };`
  - correct `pkgsLib` / `system` / `modules` wiring
  - matching `mkHomeManagerModule` block with `extraSpecialArgs = { pkgs-unstable = mkPkgsUnstable "<system>"; };`
  - HM user mapping including `_module.args.user` compatibility.

Validation:
- generated result includes clear next-step for `flake.nix` wiring

### 6) Flake package + app wiring

- Add `packages.${system}.setup-template` in `eachDefaultSystem`.
- Add `apps.${system}.setup-template` pointing to binary.
- Build package with pinned Rust toolchain from flake inputs.

Validation:
- `nix build .#setup-template`
- `nix run .#setup-template -- --help`

### 7) Dev shell alignment

- Add same pinned `rustc`/`cargo` toolchain to `devShells.default`.
- Add pinned `rust-analyzer` from same source.
- Keep existing shell tools (`bd`, `sops`, `age`, etc.).

Validation:
- `rustc --version`
- `cargo --version`

### 8) Deploy, network, and secrets support

- Deploy:
  - generate host `configuration.nix` wiring that matches the canonical pattern captured in Step 0:
    - `deploy = import ../../configs/deploy { inherit pkgs; };`
    - add `(deploy.mkLocalDeployScript { ... })` or `(deploy.mkDeployScript { ... })` in `environment.systemPackages`
  - do not modify `configs/deploy/default.nix` (reuse existing helper API only)
- Network:
  - either scaffold `configs/network.nix` entry for new hosts, or emit explicit manual checklist
- Secrets:
  - document age key retrieval, `.sops.yaml` updates, and new `secrets/<host>.yaml` creation

Validation:
- desktop template uses `mkLocalDeployScript`
- server template uses `mkDeployScript`
- docs contain network + sops onboarding steps

### 9) Documentation (required)

- Update `README.md` with `Setup Template Generator` section:
  - quick start
  - interactive + config-driven examples
  - safety flags (`--dry-run`, `--force`)
  - reference to flake wiring strategy
- Add `docs/setup-template-usage.md` for end users:
  - what gets generated
  - where to edit first
  - deploy script behavior
  - Darwin/NixOS build/switch commands
  - network/secrets follow-up steps
  - troubleshooting
- Update README ToC and link the guide prominently.

Validation:
- README ToC includes generator docs
- `docs/setup-template-usage.md` exists and is linked

### 10) CI and `flake check` coverage

- Add generator build/tests to flake checks so `nix flake check` covers it.
- Ensure CI runs those checks.

Validation:
- `nix flake check` includes setup-template checks

## Definition of done

- `nix run github:ijohanne/dotfiles-ng#setup-template` works.
- Interactive and non-interactive modes both work with validated config errors.
- Generated output follows current flake architecture.
- Rust pinning is consistent across package build and dev shell.
- Deploy script behavior is generated and documented.
- Network + sops follow-up is scaffolded or explicitly documented.
- README + ToC + `docs/setup-template-usage.md` are complete.
- `nix flake check` covers generator build/tests.
- Spike artifact (renderer contract) exists and matches implemented renderer behavior.
