{ pkgs, lib, ... }:

{
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

  programs.starship = {
    enable = true;
    enableFishIntegration = false;
    settings = { };
  };

  programs.htop = {
    enable = true;
    settings.color_scheme = 6;
  };

  programs.home-manager.enable = true;

  programs.password-store.enable = true;

  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];
  };

  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme = {
        activeBorderColor = [ "#89b4fa" "bold" ];
        inactiveBorderColor = [ "#a6adc8" ];
        optionsTextColor = [ "#89b4fa" ];
        selectedLineBgColor = [ "#313244" ];
        cherryPickedCommitBgColor = [ "#45475a" ];
        cherryPickedCommitFgColor = [ "#89b4fa" ];
        unstagedChangesColor = [ "#f38ba8" ];
        defaultFgColor = [ "#cdd6f4" ];
        searchingActiveBorderColor = [ "#f9e2af" ];
      };
      gui.authorColors = {
        "dependabot[bot]" = "#a6adc8";
      };
      gui.nerdFontsVersion = "3";
      gui.showFileIcons = true;
    };
  };

  programs.delta.enable = true;
}
