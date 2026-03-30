{ lib, user, pkgs, ... }:
let
  isDeveloper = user.developer or false;
  opencodePackage = pkgs.opencode;
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
