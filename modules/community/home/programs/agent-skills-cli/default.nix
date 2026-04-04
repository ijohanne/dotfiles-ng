{ lib, user, inputs, pkgs, ... }:
let
  isDeveloper = user.developer or false;
  system = pkgs.stdenv.hostPlatform.system;
in
lib.mkIf isDeveloper {
  home.packages = [
    inputs.ijohanne-nur.legacyPackages.${system}.agent-skills-cli
  ];
}
