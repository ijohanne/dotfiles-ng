{ config, lib, pkgs, ... }:
let
  cfg = config.programs.impeccable;
  dataDir = "${cfg.package}/share/impeccable";
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
    claudeCode.enable = lib.mkEnableOption "user-wide Impeccable skills and agents for Claude Code";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = lib.mkMerge [
      (lib.mkIf cfg.codex.enable {
        ".agents/skills/impeccable".source = "${dataDir}/agents/skills/impeccable";
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
