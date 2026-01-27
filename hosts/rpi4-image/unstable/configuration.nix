{ lib, ... }:

{
  imports = [
    ../base.nix
  ];

  system.stateVersion = "25.05";

  networking.hostName = lib.mkForce "rpi4-unstable";
}
