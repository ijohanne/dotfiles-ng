{ pkgs, user, ... }:

{
  imports = [
    (import ./common.nix {})
    (import ../programs/bash {})
    (import ../programs/zsh {})
  ];

  programs.${user.shell}.enable = true;
}
