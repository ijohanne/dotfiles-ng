{ config, pkgs, lib, user, modules, ... }:

{
  imports = [
    (import modules.private.home.users.ij { desktop = true; })
  ];

  home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
    config.xdg.configFile."ghostty/config".source;

  home.activation.setupAuthorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    cat > "$HOME/.ssh/authorized_keys" << 'EOF'
    ${lib.concatStringsSep "\n" user.sshKeys}
    EOF
    chmod 600 "$HOME/.ssh/authorized_keys"
  '';
}
