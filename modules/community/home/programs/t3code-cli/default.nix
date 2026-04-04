{ lib, user, inputs, pkgs, ... }:
let
  isDeveloper = user.developer or false;
  system = pkgs.stdenv.hostPlatform.system;
  t3codeCliPackage = inputs.t3code-nix.packages.${system}.t3code-cli;
in
lib.mkIf isDeveloper {
  home.packages = [
    t3codeCliPackage
  ];
}
