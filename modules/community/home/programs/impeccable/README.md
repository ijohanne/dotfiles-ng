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
    codex.hooks.enable = true;
    claudeCode.enable = true;
  };
}
```

- Codex: `~/.agents/skills/impeccable`, including its nested agent definitions.
- Claude Code: `~/.claude/skills/impeccable` and individual
  `~/.claude/agents/impeccable-*.md` files.
- CLI: `impeccable` on the user's PATH.
- Optional Codex lifecycle hooks: `~/.codex/hooks.json`.

Each skill launcher uses the engine bundled in the Nix package. Both the skill
archive and engine binary have fixed versions and hashes; first use does not
need to download an engine. Home Manager owns only Impeccable's paths, so other
skills and agents can coexist. Restart the tools after activation to discover
the skill.

## Codex hooks

`codex.hooks.enable` defaults to false and is enabled on `macbook`. It requires
`codex.enable` and registers the Codex manifest shipped in the pinned skill
archive. Version 4.7.0 defines `PostToolUse` (`Edit|Write|apply_patch`, 5 seconds)
and `Stop` (30 seconds). Event definitions, matchers, timeouts, and status messages
come from upstream. Command handlers invoke `${cfg.package}/bin/impeccable hook`
directly; Windows command overrides are omitted on this macOS package.

The manifest is generated at build time, so package updates also update the hook
definitions without import-from-derivation. Other Home Manager modules can append
matcher groups to the same event or add events through `codex.hooks.extraHooks`:

```nix
programs.impeccable.codex.hooks.extraHooks.Stop = [{
  hooks = [{
    type = "command";
    command = "${pkgs.my-check}/bin/my-check";
    timeout = 10;
  }];
}];
```

Home Manager owns the entire generated `~/.codex/hooks.json`. Migrate any existing
unmanaged entries into `extraHooks` before activation; the module does not force
overwrite existing files. Multiple definitions of `extraHooks` merge event lists.
Avoid registering Impeccable again in a project manifest or inline TOML: Codex runs
all matching hooks from all sources.

After activation, open `/hooks` in Codex CLI and review and trust the new hooks.
Codex tracks trust against each hook definition; package upgrades change the
command's store path and require review again. The module never writes trust state.
See [Codex hook trust](https://learn.chatgpt.com/docs/hooks#review-and-trust-hooks).

Keep project detector preferences and `hook.enabled` in `.impeccable/config.json`.
Impeccable consent does not replace Codex hook trust. For Phoenix templates, add
`"detector": { "extensions": [{ "ext": ".heex", "engine": "html" }] }` to the
project config; this adds to the built-in extensions. Claude Code automatic hooks
remain outside this module's configuration.

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
