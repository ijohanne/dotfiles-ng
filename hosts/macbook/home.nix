{ config, pkgs, lib, user, inputs, ... }:

{
  imports = [
    ../../configs
    ../../configs/dev.nix
    ../../configs/flutter.nix
    ../../configs/users/ij-base.nix
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
      #inputs.opencode.packages.${pkgs.system}.default.out
      inputs.claude-code-nix.packages.${pkgs.system}.claude-code
      tealdeer
      procs
      doggo
      inputs.beads.packages.${pkgs.system}.default
      cocoapods
    ];
  };

  home.activation.setupAuthorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    cat > "$HOME/.ssh/authorized_keys" << 'EOF'
${lib.concatStringsSep "\n" user.sshKeys}
EOF
    chmod 600 "$HOME/.ssh/authorized_keys"
  '';

  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    config.xdg.configFile."ghostty/config".source;

  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks."*" = {
        forwardAgent = true;
        extraOptions = {
          PubkeyAuthentication = "unbound";
        };
      };
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        function deploy-macbook
            command deploy-macbook
        end
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

    ghostty = {
      enable = true;
      package = pkgs.ghostty-bin;
      enableFishIntegration = true;
      settings = {
        font-family = "JetBrainsMono Nerd Font";
        font-size = 14;
        theme = "Catppuccin Mocha";
        auto-update = "off";
        macos-titlebar-style = "native";
        term = "xterm-256color";
        quit-after-last-window-closed = "true";
      };
    };

  };

  xdg.configFile."procs/config.toml".text = ''
    [[columns]]
    kind = "Pid"
    style = "BrightYellow|Yellow"
    numeric_search = true
    nonnumeric_search = false

    [[columns]]
    kind = "User"
    style = "BrightGreen|Green"
    numeric_search = false
    nonnumeric_search = true

    [[columns]]
    kind = "Separator"
    style = "White|BrightBlack"

    [[columns]]
    kind = "Tty"
    style = "BrightWhite|Black"

    [[columns]]
    kind = "UsageCpu"
    style = "ByPercentage"
    align = "Right"

    [[columns]]
    kind = "UsageMem"
    style = "ByPercentage"
    align = "Right"

    [[columns]]
    kind = "CpuTime"
    style = "BrightCyan|Cyan"

    [[columns]]
    kind = "MultiSlot"
    style = "ByUnit"
    align = "Right"

    [[columns]]
    kind = "Separator"
    style = "White|BrightBlack"

    [[columns]]
    kind = "Command"
    style = "BrightWhite|Black"
    nonnumeric_search = true

    [display]
    cut_to_terminal = false
    cut_to_pager = false
    cut_to_pipe = false
  '';
}
