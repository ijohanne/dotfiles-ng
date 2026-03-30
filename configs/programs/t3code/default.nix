{ lib, inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  t3codeDesktopPackage = inputs.t3code-nix.packages.${system}.t3code-desktop;
in
{
  home.packages = [
    t3codeDesktopPackage
  ];
}
