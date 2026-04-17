{ desktop ? false }:

{ pkgs, lib, user, modules, ... }:

let
  desktopApps = modules.public.lib.desktopApps;
in
{
  imports = [
    (import modules.public.homeManager.aspects.developerBase { inherit desktop; })
  ];

  home = {
    packages = lib.optionals desktop (
      map (app: pkgs.${app.nixPackage}) (
        builtins.filter (app: app ? nixPackage && (!pkgs.stdenv.isDarwin || !(app ? brewCask))) desktopApps
      )
    );
  };

  home.activation.importGpgKey = lib.mkIf desktop (lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    gpg --import "${../../../../secrets/ij-public-key.gpg}" 2>/dev/null || true
  '');

  home.activation.tldrUpdate = lib.hm.dag.entryAfter ([ "writeBoundary" ] ++ lib.optional desktop "importGpgKey") ''
    ${pkgs.tealdeer}/bin/tldr --update 2>/dev/null || true
  '';

  services.gpg-agent = lib.mkIf (!pkgs.stdenv.isDarwin && desktop) {
    enable = true;
    enableSshSupport = true;
  };

  programs.fish.enable = true;
}
