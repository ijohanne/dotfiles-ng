{ config, lib, pkgs, ... }:
let
  cfg = config.programs.impeccable;
  dataDir = "${cfg.package}/share/impeccable";
  jsonFormat = pkgs.formats.json { };
  codexHooks = pkgs.runCommand "impeccable-codex-hooks.json"
    { nativeBuildInputs = [ pkgs.jq ]; }
    ''
      jq --arg command ${lib.escapeShellArg "${cfg.package}/bin/impeccable hook"} \
        --slurpfile extra ${jsonFormat.generate "codex-extra-hooks.json" cfg.codex.hooks.extraHooks} '
        .hooks |= with_entries(.value |= map(.hooks |= map(
          if .type == "command" then
            .command = $command | del(.commandWindows)
          else . end
        )))
        | reduce ($extra[0] | to_entries[]) as $event (. ;
            .hooks[$event.key] = ((.hooks[$event.key] // []) + $event.value))
      ' ${dataDir}/codex/hooks.json > "$out"
    '';
  claudeAgents = [
    "impeccable-asset-producer"
    "impeccable-documenter"
    "impeccable-finish-reviewer"
    "impeccable-manual-edit-applier"
  ];
in
{
  options.programs.impeccable = {
    enable = lib.mkEnableOption "Impeccable design skills and CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../../packages/impeccable { };
      description = "Impeccable package containing the skills and pinned engine.";
    };

    codex.enable = lib.mkEnableOption "user-wide Impeccable skills for Codex";
    codex.hooks = {
      enable = lib.mkEnableOption "user-wide Impeccable lifecycle hooks for Codex";

      extraHooks = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf jsonFormat.type);
        default = { };
        description = ''
          Additional Codex matcher groups, keyed by event, to append to the
          pinned Impeccable hooks in ~/.codex/hooks.json. Definitions from
          multiple Home Manager modules are merged. Existing unmanaged files
          must be migrated here before Home Manager takes ownership.
        '';
      };
    };
    claudeCode.enable = lib.mkEnableOption "user-wide Impeccable skills and agents for Claude Code";
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = !cfg.codex.hooks.enable || cfg.codex.enable;
      message = "programs.impeccable.codex.hooks.enable requires programs.impeccable.codex.enable.";
    }];

    home.packages = [ cfg.package ];

    home.file = lib.mkMerge [
      (lib.mkIf cfg.codex.enable {
        ".agents/skills/impeccable".source = "${dataDir}/agents/skills/impeccable";
      })
      (lib.mkIf cfg.codex.hooks.enable {
        ".codex/hooks.json".source = codexHooks;
      })
      (lib.mkIf cfg.claudeCode.enable (
        {
          ".claude/skills/impeccable".source = "${dataDir}/claude/skills/impeccable";
        } // lib.genAttrs
          (map (name: ".claude/agents/${name}.md") claudeAgents)
          (path: { source = "${dataDir}/claude/agents/${builtins.baseNameOf path}"; })
      ))
    ];
  };
}
