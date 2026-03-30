{ desktop ? false }:
{ pkgs, lib, user, inputs, ... }:
{
  programs.fish = {
    shellInit = ''
      set -p fish_function_path ${inputs.fish-eza}/functions $fish_function_path
    '';
    shellAliases = {
      du = "${pkgs.dust}/bin/dust";
      top = "${pkgs.htop}/bin/htop";
      la = "eza -la";
      lx = "eza -la --sort=size";
      llm = "eza -l --icons=always";
      tree = "eza --tree";
      lt = "eza --tree -L 2";
    };
    interactiveShellInit = lib.concatStringsSep "\n" ([
      ''
        if not set -q SSH_CONNECTION; or not set -q SSH_AUTH_SOCK
            export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket 2>/dev/null || echo "$HOME/.gnupg/S.gpg-agent.ssh")"
        end
        abbr -a ps procs
        function dog
            ${pkgs.doggo}/bin/doggo $argv
        end
        function dig
            dog $argv
        end
        function vim
            nvim $argv
        end
        function vi
            nvim $argv
        end
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
        set -g fish_greeting ""
        set -gx SOPS_AGE_KEY_FILE "$HOME/.config/sops/age/keys.txt"
        if test -f /run/secrets/gitea_homebrew_api_token
            set -gx GITEA_HOMEBREW_API_TOKEN (cat /run/secrets/gitea_homebrew_api_token)
        end
      ''
    ]
    ++ lib.optionals desktop [
      ''
        set -p PATH $HOME/.nix-profile/bin
        set -p PATH /etc/profiles/per-user/${user.username}/bin
        set -p PATH /run/current-system/sw/bin
        set -p PATH /nix/var/nix/profiles/default/bin
        ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent 2>/dev/null || true
        export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket 2>/dev/null || echo "$HOME/.gnupg/S.gpg-agent.ssh")"
        function nix_rebuild_switch
            if command -q deploy-macbook
                command deploy-macbook
            else if command -q deploy-ij-desktop
                command deploy-ij-desktop
            else
                echo "No deploy command found for this host"
                return 1
            end
        end
      ''
    ]);
  };
}
