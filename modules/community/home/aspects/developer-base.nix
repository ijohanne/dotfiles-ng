{ desktop ? false }:
{
  imports = [
    (import ./cli-base.nix { inherit desktop; })
    (import ../../../../configs/programs/fish { inherit desktop; })
    (import ../../../../configs/programs/tmux { inherit desktop; })
    (import ../../../../configs/programs/git { })
    (import ../../../../configs/programs/bash { })
    (import ../../../../configs/programs/direnv { })
    (import ../../../../configs/programs/lazygit { })
    (import ../../../../configs/programs/starship { })
    (import ../../../../configs/programs/htop { })
    (import ../../../../configs/programs/zoxide { })
    (import ../../../../configs/programs/delta { })
    (import ../../../../configs/programs/procs { })
    ../../../../configs/programs/neovim
    ../../../../configs/programs/lorri
    ../../../../configs/programs/agent-skills-cli
    ../../../../configs/programs/leita
    ../../../../configs/programs/vardrun
    ../../../../configs/programs/callis
  ] ++ (if desktop then [
    (import ../../../../configs/programs/ghostty { })
    (import ../../../../configs/programs/ssh { desktop = true; })
    ../../../../configs/programs/zed
    ../../../../configs/programs/t3code
    ../../../../configs/dev/languages
  ] else [
    ../../../../configs/dev/languages/nix
    ../../../../configs/dev/languages/lua
    ../../../../configs/dev/languages/markdown
  ]);
}
