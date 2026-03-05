{ config, pkgs, lib, user, ... }:

{
  home = {
    stateVersion = "22.05";
    username = "mj";
    homeDirectory = "/home/mj";
  };

  programs = {
    zsh.enable = true;
    home-manager.enable = true;
  };
}
