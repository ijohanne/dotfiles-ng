# Impeccable

Home Manager installs the pinned Impeccable CLI, design skills, and supporting
agents. The package currently supports Apple Silicon macOS. Only `macbook`
imports and enables this module in this repository.

```nix
{
  imports = [ modules.public.homeManager.programs.impeccable ];

  programs.impeccable = {
    enable = true;
    codex.enable = true;
    claudeCode.enable = true;
  };
}
```

- Codex: `~/.agents/skills/impeccable`, including its nested agent definitions.
- Claude Code: `~/.claude/skills/impeccable` and individual
  `~/.claude/agents/impeccable-*.md` files.
- CLI: `impeccable` on the user's PATH.

Each skill launcher uses the engine bundled in the Nix package. Both the skill
archive and engine binary have fixed versions and hashes; first use does not
need to download an engine. Home Manager owns only Impeccable's paths, so other
skills and agents can coexist. Restart the tools after activation to discover
the skill.

Automatic edit hooks are not configured by this module. In particular, Codex
hooks are project-local and require project trust. See the
[upstream installation documentation](https://github.com/pbakaus/impeccable#installation)
when adding hooks to a project.

## Updating

Update `version`, `engineVersion`, and both `fetchurl` hashes in
`modules/community/packages/impeccable/default.nix`. Upstream releases the skill
as `skill-v<VERSION>/universal.zip` and the engine separately as
`engine-v<VERSION>/impeccable-darwin-arm64`. Use `nix store prefetch-file --json`
with each release asset URL to obtain its hash. The package checks that the
skill's engine version matches and that both provider launchers run successfully.

Build with `nix build .#impeccable`, run `nix flake check`, and build the MacBook
configuration before activating with `darwin-rebuild switch --flake .#macbook`.
Update through Nix rather than `impeccable update`, since the installed files
are read-only Nix store paths.
