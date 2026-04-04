{ lib, user, inputs, pkgs, ... }:
let
  isDeveloper = user.developer or false;
  system = pkgs.stdenv.hostPlatform.system;
  opencodePackage = inputs.llm-agents-nix.packages.${system}.opencode;
  opencodeUnsafe = pkgs.writeShellScriptBin "opencode-unsafe" ''
    export OPENCODE_PERMISSION='"allow"'
    exec ${opencodePackage}/bin/opencode "$@"
  '';
in
lib.mkIf isDeveloper {
  home.packages = [
    opencodePackage
    opencodeUnsafe
  ];
}
