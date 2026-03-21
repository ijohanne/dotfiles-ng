{ lib, user, inputs, pkgs, ... }:
let
  isDeveloper = user.developer or false;
in
lib.mkIf isDeveloper {
  home.packages = [
    inputs.ijohanne-nur.legacyPackages.${pkgs.system}.agent-skills-cli
  ];
}
