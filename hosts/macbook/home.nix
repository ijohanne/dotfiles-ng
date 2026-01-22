{ pkgs, lib, user, inputs, ... }:

{
  imports = [
    ../../configs
    ../../configs/dev.nix
  ];

  home = {
    stateVersion = "23.05";

    packages = with pkgs; [
      coreutils
      zip
      unzip
      tmux
      sqlite
      ripgrep
      openssl
      postgresql
      fzf
      difftastic
      nushell
      atuin
      mpv
      python3
      jq
      yq
      qbittorrent
      wget
      dive
      ffmpeg
      shellcheck
      pyenv
      kubernetes-helm
      kind
      ansible
      gopass
      gnupg
      yubikey-manager
      yubikey-agent
      age-plugin-yubikey
      starship
      dockutil
      inputs.opencode.packages.${pkgs.system}.default.out
      tealdeer
      procs
      doggo
    ];
  };

  home.activation.importGpgKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gpg --import "${../../secrets/ij-public-key.gpg}" 2>/dev/null || true
  '';

  home.activation.tldrUpdate = lib.hm.dag.entryAfter [ "importGpgKey" ] ''
    ${pkgs.tealdeer}/bin/tldr --update 2>/dev/null || true
  '';

  home.activation.configureDock = lib.hm.dag.entryAfter [ "importGpgKey" ] ''
    ${pkgs.dockutil}/bin/dockutil --remove all --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /Applications/Google\ Chrome.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /System/Applications/System\ Settings.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /System/Applications/Calendar.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /System/Applications/Notes.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /System/Applications/Reminders.app --no-restart
    ${pkgs.dockutil}/bin/dockutil --add /System/Applications/Photos.app --no-restart
    /usr/bin/killall Dock
  '';

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  programs = {
    fish = {
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
      '';
    };

    starship = {
      enable = true;
      enableFishIntegration = false;
      settings = {
      };
    };

    htop = {
      enable = true;
      settings.color_scheme = 6;
    };

    home-manager = {
      enable = true;
    };

    password-store = {
      enable = true;
    };

    git = {
      enable = true;
      settings = {
        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";
        merge.conflictstyle = "diff3";
        diff.color = "auto";
        diff.mnemonicPrefix = true;
        diff.relativeDate = true;
      };
    };

    kitty = {
      enable = true;
      font = {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
        size = 14;
      };
    };

    zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };

    lazygit = {
      enable = true;
      settings = {
        gui.theme = {
          activeBorderColor = [ "#89b4fa" "bold" ];
          inactiveBorderColor = [ "#a6adc8" ];
          optionsTextColor = [ "#89b4fa" ];
          selectedLineBgColor = [ "#313244" ];
          cherryPickedCommitBgColor = [ "#45475a" ];
          cherryPickedCommitFgColor = [ "#89b4fa" ];
          unstagedChangesColor = [ "#f38ba8" ];
          defaultFgColor = [ "#cdd6f4" ];
          searchingActiveBorderColor = [ "#f9e2af" ];
        };
        gui.authorColors = {
          "dependabot[bot]" = "#a6adc8";
        };
        gui.nerdFontsVersion = "3";
        gui.showFileIcons = true;
      };
    };

    delta = {
      enable = true;
    };
  };
}
