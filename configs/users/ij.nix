{ desktop ? false }:

{ pkgs, lib, user, inputs, ... }:

{
  imports = [
    (import ./common.nix { inherit desktop; })
    (import ../programs/fish { inherit desktop; })
    (import ../programs/tmux { inherit desktop; })
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
    ../programs/agent-skills-cli
    ../programs/leita
    ../programs/vardrun
    ../programs/callis
  ] ++ (if desktop then [
    (import ../programs/ghostty {})
    (import ../programs/ssh { desktop = true; })
    ../programs/zed
    ../dev/languages
  ] else [
    ../dev/languages/nix.nix
    ../dev/languages/lua.nix
    ../dev/languages/markdown.nix
  ]);

  home = {
    stateVersion = lib.mkDefault "22.05";
    username = user.username;
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${user.username}" else "/home/${user.username}";
    packages = lib.optionals (desktop && !pkgs.stdenv.isDarwin) (with pkgs; [
      google-chrome
      mattermost-desktop
      docker
      slack
      libreoffice
      discord
      opencode
      notion-app-enhanced
    ]);
  };

  home.activation.importGpgKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gpg --import "${../../secrets/ij-public-key.gpg}" 2>/dev/null || true
  '';

  home.activation.tldrUpdate = lib.hm.dag.entryAfter [ "importGpgKey" ] ''
    ${pkgs.tealdeer}/bin/tldr --update 2>/dev/null || true
  '';

  services.gpg-agent = lib.mkIf (!pkgs.stdenv.isDarwin) {
    enable = true;
    enableSshSupport = true;
  };

  programs.password-store.enable = true;

  programs.fish.enable = true;
}
