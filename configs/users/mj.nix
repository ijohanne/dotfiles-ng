{ pkgs, user, ... }:

{
  imports = [
    (import ./common.nix {})
    (import ../programs/bash {})
  ];

  home = {
    stateVersion = "22.05";
    username = user.username;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${user.username}" else "/home/${user.username}";
  };

  programs.${user.shell}.enable = true;
}
