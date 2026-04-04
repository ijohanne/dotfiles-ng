{ desktop ? false }:
{
  imports = [
    (import ./cli-base.nix { inherit desktop; })
    (import ../programs/fish { inherit desktop; })
    (import ../programs/tmux { inherit desktop; })
    (import ../programs/git { })
    (import ../programs/bash { })
    (import ../programs/direnv { })
    (import ../programs/lazygit { })
    (import ../programs/starship { })
    (import ../programs/htop { })
    (import ../programs/zoxide { })
    (import ../programs/delta { })
    (import ../programs/procs { })
    ../programs/neovim
    ../programs/lorri
    ../programs/agent-skills-cli
    ../programs/leita
    ../programs/vardrun
    ../programs/callis
  ] ++ (if desktop then [
    (import ../programs/ghostty { })
    (import ../programs/ssh { desktop = true; })
    ../programs/zed
    ../programs/t3code
    ../languages
  ] else [
    ../languages/nix
    ../languages/lua
    ../languages/markdown
  ]);
}
