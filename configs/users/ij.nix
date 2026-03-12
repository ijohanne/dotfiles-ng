{ pkgs, lib, user, ... }:

{
  imports = [
    (import ./common.nix {})
    (import ../programs/fish {})
    (import ../programs/tmux {})
    (import ../programs/git {})
    (import ../programs/bash {})
    (import ../programs/direnv {})
    (import ../programs/lazygit {})
    (import ../programs/starship {})
    (import ../programs/htop {})
    (import ../programs/zoxide {})
    (import ../programs/delta {})
    (import ../programs/procs {})
    ../programs/neovim
    ../programs/lorri
    ../dev/languages/nix.nix
    ../dev/languages/lua.nix
    ../dev/languages/markdown.nix
  ];

  home = {
    stateVersion = "22.05";
    username = user.username;
    homeDirectory = "/home/${user.username}";
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
