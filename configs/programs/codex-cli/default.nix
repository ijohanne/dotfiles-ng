{ lib, user, inputs, pkgs, ... }:
let
  isDeveloper = user.developer or false;
  codexPackage = inputs.codex-cli-nix.packages.${pkgs.system}.codex;
  codexUnsafe = pkgs.writeShellScriptBin "codex-unsafe" ''
    exec ${codexPackage}/bin/codex --dangerously-bypass-approvals-and-sandbox "$@"
  '';
in
lib.mkIf isDeveloper {
  home.packages = [
    codexPackage
    codexUnsafe
  ];
}
