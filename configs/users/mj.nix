{ pkgs, user, ... }:

{
  imports = [
    (import ./common.nix {})
    (import ../programs/bash {})
  ];

  programs.${user.shell}.enable = true;
}
