{ pkgs, lib, user, ... }:

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
    ];
  };

  home.activation.importGpgKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gpg --import "${../../secrets/ij-public-key.gpg}" 2>/dev/null || true
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

    kitty = {
      enable = true;
      font = {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
        size = 14;
      };
    };
  };
}
