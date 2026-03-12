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
    (import ../../configs/programs/ssh { desktop = true; })
    (import ../../configs/programs/procs {})
    ../../configs/programs/neovim
    ../../configs/programs/lorri
    ../../configs/programs/zed
    ../../configs/dev/languages
  ];

  home = {
    stateVersion = "23.05";

    packages = with pkgs; [
      coreutils
      qbittorrent
      dive
      ffmpeg
      pyenv
      kubernetes-helm
      kind
      ansible
      gopass
      cocoapods
      postgresql
    ];
  };

  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    config.xdg.configFile."ghostty/config".source;

  home.activation.importGpgKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gpg --import "${../../secrets/ij-public-key.gpg}" 2>/dev/null || true
  '';

  home.activation.tldrUpdate = lib.hm.dag.entryAfter [ "importGpgKey" ] ''
    ${pkgs.tealdeer}/bin/tldr --update 2>/dev/null || true
  '';

  home.activation.setupAuthorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    cat > "$HOME/.ssh/authorized_keys" << 'EOF'
${lib.concatStringsSep "\n" user.sshKeys}
EOF
    chmod 600 "$HOME/.ssh/authorized_keys"
  '';

  programs.password-store.enable = true;
  programs.fish.enable = true;
}
