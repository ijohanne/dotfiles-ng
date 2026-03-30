{ lib, user, inputs, pkgs, ... }:
let
  isDeveloper = user.developer or false;
  system = pkgs.stdenv.hostPlatform.system;
  codexPackage = inputs.codex-cli-nix.packages.${system}.codex;
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
