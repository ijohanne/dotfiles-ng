{ config, pkgs, lib, user, inputs, ... }:

{
  imports = [
    ../../configs
    ../../configs/dev.nix
    ../../configs/flutter.nix
  ];

  home = {
    stateVersion = "23.05";
    username = user.username;
    homeDirectory = "/home/${user.username}";

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      zip
      unzip
      tmux
      vscode
      google-chrome
      spotify
      mattermost-desktop
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
      flameshot
      docker
      gnupg
      yubioath-flutter
      yubikey-agent
      age-plugin-yubikey
      starship
      inputs.opencode.packages.${pkgs.system}.default.out
      inputs.claude-code-nix.packages.${pkgs.system}.claude-code
      tealdeer
      procs
      doggo
      notion-app-enhanced
      inputs.beads.packages.${pkgs.system}.default
    ];
  };

  home.activation.importGpgKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gpg --import "${../../secrets/ij-public-key.gpg}" 2>/dev/null || true
  '';

  home.activation.tldrUpdate = lib.hm.dag.entryAfter [ "importGpgKey" ] ''
    ${pkgs.tealdeer}/bin/tldr --update 2>/dev/null || true
  '';

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = ''
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null || echo "$HOME/.gnupg/S.gpg-agent.ssh")"
        abbr -a tldr tealdeer
        abbr -a ps procs
        function dog
            ${pkgs.doggo}/bin/dog $argv
        end
        function dig
            dog $argv
        end
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

    ghostty = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        font-family = "JetBrainsMono Nerd Font";
        font-size = 14;
        theme = "Catppuccin Mocha";
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
  };
}
