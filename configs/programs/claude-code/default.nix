{ lib, user, inputs, pkgs, ... }:
let
  isDeveloper = user.developer or false;
  system = pkgs.stdenv.hostPlatform.system;
  claudePackage = inputs.claude-code-nix.packages.${system}.claude-code;
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
