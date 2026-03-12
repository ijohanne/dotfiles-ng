{ lib, ... }:

{
  imports = [
    ../base.nix
  ];

  networking.hostName = lib.mkForce "rpi4-unstable";

  system.stateVersion = "25.05";
}
