{ desktop ? false }:

{ pkgs, lib, user, inputs, ... }:

let
  desktopApps = import ../programs/desktop-apps.nix;
in
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
    ../dev/languages/nix
    ../dev/languages/lua
    ../dev/languages/markdown
  ]);

  home = {
    packages = lib.optionals desktop (
      map (app: pkgs.${app.nixPackage}) (
        builtins.filter (app: app ? nixPackage && (!pkgs.stdenv.isDarwin || !(app ? brewCask))) desktopApps
      )
    );
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


  programs.fish.enable = true;
}
