{ pkgs, user, ... }:

{
  imports = [
    (import ../../modules/community/home/aspects/cli-base.nix { })
    (import ../programs/bash { })
    (import ../programs/zsh { })
  ];

  programs.${user.shell}.enable = true;
}
