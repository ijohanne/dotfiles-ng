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
    (import ../../configs/ssh { desktop = true; })
    (import ../../configs/procs {})
    ../../configs/dev.nix
    ../../configs/flutter.nix
    ../../configs/zed
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
