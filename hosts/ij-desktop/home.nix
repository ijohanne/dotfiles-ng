{ config, pkgs, lib, user, inputs, ... }:

{
  imports = [
    (import ../../configs/users/common.nix { desktop = true; })
    (import ../../configs/programs/fish { desktop = true; })
    (import ../../configs/programs/tmux { desktop = true; })
    (import ../../configs/programs/git {})
    (import ../../configs/programs/bash {})
    (import ../../configs/programs/direnv {})
    (import ../../configs/programs/lazygit {})
    (import ../../configs/programs/starship {})
    (import ../../configs/programs/htop {})
    (import ../../configs/programs/zoxide {})
    (import ../../configs/programs/delta {})
    (import ../../configs/programs/ghostty {})
    (import ../../configs/programs/kitty {})
    (import ../../configs/programs/procs {})
    ../../configs/programs/neovim
    ../../configs/programs/lorri
    ../../configs/programs/zed
    ../../configs/dev/languages
  ];

  home = {
    stateVersion = "23.05";
    username = user.username;
    homeDirectory = "/home/${user.username}";

    packages = with pkgs; [
      vscode
      google-chrome
      spotify
      mattermost-desktop
      mpv
      qbittorrent
      dive
      ffmpeg
      flameshot
      docker
      yubioath-flutter
      inputs.opencode.packages.${pkgs.system}.default.out
      notion-app-enhanced
      postgresql
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

  programs.password-store.enable = true;
  programs.fish.enable = true;
}
