{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      function nix_rebuild_switch
          set -l oldpwd (pwd)
          cd $HOME/dotfiles && sudo darwin-rebuild switch --flake .#macbook
          cd $oldpwd
      end
      abbr -a nix-rebuild-switch nix_rebuild_switch
      function vim
          nvim $argv
      end
      function vi
          nvim $argv
      end
      set -g fish_greeting ""
      set -p PATH $HOME/.nix-profile/bin
      set -p PATH /etc/profiles/per-user/ij/bin
      set -p PATH /run/current-system/sw/bin
      set -p PATH /nix/var/nix/profiles/default/bin
      gpgconf --launch gpg-agent 2>/dev/null || true
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null || echo "$HOME/.gnupg/S.gpg-agent.ssh")"

      function ta
          set -l session (tmux list-sessions -F '#{session_name}' 2>/dev/null | fzf --height 40% --reverse)
          if test -n "$session"
              tmux attach-session -t "$session"
          end
      end

      function tat
          if test -z "$argv"
              set -l new_name (tmux display-message -p '#S')
          else
              set -l new_name $argv[1]
          end
          tmux new-session -A -s "$new_name"
      end

      function tka
          tmux kill-server
      end

      function tks
          tmux kill-session
      end

      function tls
          tmux list-sessions
      end

      abbr -a tldr tealdeer
      abbr -a ps procs
      function dig
          dog $argv
      end
    '';
  };
}
