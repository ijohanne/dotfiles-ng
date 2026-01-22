{ config, pkgs, lib, user, inputs, ... }:

{
  imports = [
    ../../configs
    ../../configs/dev.nix
  ];

  home = {
    stateVersion = "23.05";
    username = user.username;
    homeDirectory = "/home/${user.username}";

    packages = with pkgs; [
      kitty
      zip
      unzip
      tmux
      vscode
      google-chrome
      spotify
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
    ];
  };

  home.activation.importGpgKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gpg --import "${../../secrets/ij-public-key.gpg}" 2>/dev/null || true
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
  };
}
