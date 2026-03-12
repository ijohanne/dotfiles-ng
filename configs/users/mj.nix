{ pkgs, user, ... }:

{
  imports = [
    (import ./common.nix {})
    (import ../bash {})
  ];

  home = {
    stateVersion = "22.05";
    username = user.username;
    homeDirectory = "/home/${user.username}";
  };

  programs.${user.shell}.enable = true;
}
