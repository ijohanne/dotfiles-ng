{ lib, user, inputs, pkgs, ... }:
let
  isDeveloper = user.developer or false;
in
lib.mkIf isDeveloper {
  home.packages = [
    inputs.callis.packages.${pkgs.system}.default
  ];
}
