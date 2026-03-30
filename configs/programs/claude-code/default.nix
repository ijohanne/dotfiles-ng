{ lib, user, inputs, pkgs, ... }:
let
  isDeveloper = user.developer or false;
  claudePackage = inputs.claude-code-nix.packages.${pkgs.system}.claude-code;
  claudeUnsafe = pkgs.writeShellScriptBin "claude-unsafe" ''
    exec ${claudePackage}/bin/claude --dangerously-skip-permissions "$@"
  '';
in
lib.mkIf isDeveloper {
  home.packages = [
    claudePackage
    claudeUnsafe
  ];
}
