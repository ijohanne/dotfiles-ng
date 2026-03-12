{ desktop ? false }:
{ pkgs, lib, inputs, ... }:
{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    zip
    unzip
    sqlite
    ripgrep
    openssl
    fzf
    difftastic
    nushell
    atuin
    python3
    jq
    yq
    wget
    shellcheck
    gnupg
    tealdeer
    procs
    doggo
    bat
    bottom
    dust
    eza
    fd
    gping
    httpie
  ] ++ lib.optionals desktop [
    nerd-fonts.jetbrains-mono
    yubikey-manager
    yubikey-agent
    age-plugin-yubikey
    inputs.claude-code-nix.packages.${pkgs.system}.claude-code
    inputs.beads.packages.${pkgs.system}.default
  ];
}
