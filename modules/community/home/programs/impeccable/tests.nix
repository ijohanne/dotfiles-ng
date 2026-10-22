{ pkgs, lib, home-manager }:
let
  evaluate = modules: (home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ./default.nix
      {
        home.username = "impeccable-test";
        home.homeDirectory = "/Users/impeccable-test";
        home.stateVersion = "26.05";
        programs.impeccable = {
          enable = true;
          codex.enable = true;
        };
      }
    ] ++ modules;
  }).config;
  enabled = evaluate [{ programs.impeccable.codex.hooks.enable = true; }];
  disabled = evaluate [ ];
  allDisabled = evaluate [{
    programs.impeccable.enable = lib.mkForce false;
    programs.impeccable.codex.hooks.enable = true;
  }];
  merged = evaluate [
    {
      programs.impeccable.codex.hooks = {
        enable = true;
        extraHooks.Stop = [{ hooks = [{ type = "command"; command = "echo first"; }]; }];
      };
    }
    {
      programs.impeccable.codex.hooks.extraHooks = {
        Stop = [{ hooks = [{ type = "command"; command = "echo second"; }]; }];
        SessionStart = [{ hooks = [{ type = "command"; command = "echo startup"; }]; }];
      };
    }
  ];
  package = enabled.programs.impeccable.package;
in
assert !(disabled.home.file ? ".codex/hooks.json");
assert !(allDisabled.home.file ? ".codex/hooks.json");
pkgs.runCommand "impeccable-hooks-check"
{ nativeBuildInputs = [ pkgs.jq ]; }
  ''
    jq -e --slurpfile upstream ${package}/share/impeccable/codex/hooks.json \
      --arg command "${package}/bin/impeccable hook" '
      def metadata: walk(if type == "object" and .type? == "command"
        then del(.command, .commandWindows) else . end);
      (metadata == ($upstream[0] | metadata)) and
      ([.hooks[][] | .hooks[]] | all(.command == $command and (has("commandWindows") | not)))
    ' ${enabled.home.file.".codex/hooks.json".source} > /dev/null

    jq -e '
      (.hooks.PostToolUse | length) == 1 and
      (.hooks.Stop | length) == 3 and
      ([.hooks.Stop[1:][] | .hooks[].command] | sort) == ["echo first", "echo second"] and
      .hooks.SessionStart[0].hooks[0].command == "echo startup"
    ' ${merged.home.file.".codex/hooks.json".source} > /dev/null

    mkdir .impeccable
    echo '{"hook":{"enabled":false}}' > .impeccable/config.json
    for event in PostToolUse Stop; do
      jq -n --arg event "$event" --arg cwd "$PWD" \
        '{hook_event_name: $event, cwd: $cwd, tool_name: "apply_patch", tool_input: {}}' \
        | env -i HOME="$TMPDIR" PATH=/usr/bin:/bin ${package}/bin/impeccable hook > hook-output
      test ! -s hook-output
    done
    touch "$out"
  ''
