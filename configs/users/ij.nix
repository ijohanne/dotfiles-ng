{ desktop ? false }:

{ pkgs, lib, user, inputs, ... }:

let
  desktopApps = import ../profiles/apps/desktop;
in
{
  imports = [
    (import ../../modules/community/home/aspects/developer-base.nix { inherit desktop; })
  ];

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
