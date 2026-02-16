{ inputs, pkgs, self, ... }: {
  imports = [
    ./git
    ./tmux
    ./fish
    ./bash
    ./zed
  ];
}
