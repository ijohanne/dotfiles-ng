{ config, pkgs, lib, user, inputs, ... }:

{
  imports = [
    (import ../../configs/users/common.nix { desktop = true; })
    (import ../../configs/fish { desktop = true; })
    (import ../../configs/tmux { desktop = true; })
    (import ../../configs/git {})
    (import ../../configs/bash {})
    (import ../../configs/direnv {})
    (import ../../configs/lazygit {})
    (import ../../configs/starship {})
    (import ../../configs/htop {})
    (import ../../configs/zoxide {})
    (import ../../configs/delta {})
    (import ../../configs/ghostty {})
    (import ../../configs/kitty {})
    (import ../../configs/procs {})
    ../../configs/dev.nix
    ../../configs/flutter.nix
    ../../configs/zed
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
